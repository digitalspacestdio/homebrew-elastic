class FilebeatFullAT816 < Formula
  desc "File harvester to ship log files to Elasticsearch or Logstash"
  homepage "https://www.elastic.co/products/beats/filebeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.16.6-linux-arm64.tar.gz"
      sha256 "d08bc770753e9b3137d145ad38581f57e91ecf64030adff7c26eb92627f895f7"
    else
      url "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.16.6-linux-x86_64.tar.gz"
      sha256 "dcb8da47df8c42ece1b15334b5e25bb4e51fc93a325944133aa7bcdee072e453"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.16.6-darwin-aarch64.tar.gz"
      sha256 "df1a226a7fd2225d28c1cea19109d4603e2a0f34630aadc737302d946f73d025"
    else
      url "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.16.6-darwin-x86_64.tar.gz"
      sha256 "8c1e420fe1e5ab9f6347c483837c32b87048b9e3b1776e2552d38d8b49a3a04e"
    end
  end
  #end-auto-replace
  conflicts_with "filebeat"
  conflicts_with "filebeat-oss"

  def install
    ["fields.yml", "ingest", "kibana", "module"].each { |d| libexec.install d if File.exist?(d) }
    (libexec/"bin").install "filebeat"
    (etc/"filebeat").install "filebeat.yml"
    (etc/"filebeat").install "modules.d" if File.exist?("modules.d")

    (bin/"filebeat").write <<~EOS
      #!/bin/sh
      exec #{libexec}/bin/filebeat \
        --path.config #{etc}/filebeat \
        --path.data #{var}/lib/filebeat \
        --path.home #{libexec} \
        --path.logs #{var}/log/filebeat \
        "$@"
    EOS
  end

  plist_options :manual => "filebeat"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{opt_bin}/filebeat</string>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    log_file = testpath/"test.log"
    touch log_file

    (testpath/"filebeat.yml").write <<~EOS
      filebeat:
        inputs:
          -
            paths:
              - #{log_file}
            scan_frequency: 0.1s
      output:
        file:
          path: #{testpath}
    EOS

    (testpath/"log").mkpath
    (testpath/"data").mkpath

    filebeat_pid = fork do
      exec bin/"filebeat", "-c", testpath/"filebeat.yml", "-path.config",
                             testpath/"filebeat", "-path.home=#{testpath}",
                             "-path.logs", testpath/"log", "-path.data", testpath
    end
    begin
      sleep 1
      log_file.append_lines "foo bar baz"
      sleep 5

      assert_predicate testpath/"filebeat", :exist?
    ensure
      Process.kill("TERM", filebeat_pid)
    end
  end
end
