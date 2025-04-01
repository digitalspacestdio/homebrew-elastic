class FilebeatFullAT816 < Formula
  desc "File harvester to ship log files to Elasticsearch or Logstash"
  homepage "https://www.elastic.co/products/beats/filebeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.16.6-linux-arm64.tar.gz"
        sha512 "96b1b4e5b259296d5ad0fb1769bf800eef2919b5bb105103c733bb49b59001a9f2f4899e6eb16c474e4d239b5791958c7248272f71723d897408e36580c0e740"
      else
        url "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.16.6-linux-x86_64.tar.gz"
        sha512 "c40b25d7f38809f770124bb555a824e32ec8b7961b0f94935f1c896581ff3dd11886720297a36256bdabbeefcfb9176faa96f65afd58163ebc93633ebd80c745"
      end
    else
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.16.6-darwin-aarch64.tar.gz"
        sha512 "92e8e6a6296f2e72d224cb2524307cd6806af080ddbfa20e6713a2742ac305b0c299bbd7592851bcd8cc86b4f058c1e9e148ef66589af5e62d744018fd51f3ad"
      else
        url "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.16.6-darwin-x86_64.tar.gz"
        sha512 "cdaa2fbc47df542b87ee21e913edab1fc47d82cdaefe64359d64f1a869ff22cfe2a643ab36821fb3223469cc2fcec8e79e52b006c913d1b863bbc231359a1dda"
      end
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
