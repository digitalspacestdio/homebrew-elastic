class HeartbeatFullAT816 < Formula
  desc "Lightweight Shipper for Uptime Monitoring"
  homepage "https://www.elastic.co/products/beats/heartbeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.16.6-linux-arm64.tar.gz"
        sha512 "d8efd99bb5ad2390b464d54294060701f9c5b266c6284a33f3fa4d00a7a80c5c8ece3ca7f0af7cf54607a6a78b4af1954c2f3450b4c237dd97efb31e7bf3de39"
      else
        url "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.16.6-linux-x86_64.tar.gz"
        sha512 "cf30bd70ff36919b5deceac48e30a5615fa4eccf62ff1d2095939944220926893ea301a933447251542796f986cc5d117f5ab4bb28699ef12c9546450b6bebfa"
      end
    else
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.16.6-darwin-aarch64.tar.gz"
        sha512 "58805ff4769e10837c44e36c57e1ad2abe9252224d485113ecf380c943e325d1c2da39b1f046af18faf003b1c13d8a95089c11b79d6147586c3848c49453d880"
      else
        url "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.16.6-darwin-x86_64.tar.gz"
        sha512 "8ff2a7b20a51999ac83d9bacd80d46254a2b3217c80c08747ab2b5c4c0befd957065d244d88822623d9cec23ce4c65f496a25b056cd1ba3f16012da6b9edb282"
      end
    end
  end
  #end-auto-replace
  conflicts_with "heartbeat"
  conflicts_with "heartbeat-oss"

  def install
    ["fields.yml", "ingest", "kibana", "module"].each { |d| libexec.install d if File.exist?(d) }
    (libexec/"bin").install "heartbeat"
    (etc/"heartbeat").install "heartbeat.yml"
    (etc/"heartbeat").install "modules.d" if File.exist?("modules.d")

    (bin/"heartbeat").write <<~EOS
      #!/bin/sh
      exec #{libexec}/bin/heartbeat \
        --path.config #{etc}/heartbeat \
        --path.data #{var}/lib/heartbeat \
        --path.home #{libexec} \
        --path.logs #{var}/log/heartbeat \
        "$@"
    EOS
  end

  def post_install
    (var/"lib/heartbeat").mkpath
    (var/"log/heartbeat").mkpath
  end

  plist_options :manual => "heartbeat"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{opt_bin}/heartbeat</string>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    require "socket"

    server = TCPServer.new(0)
    port = server.addr[1]

    (testpath/"config/heartbeat.yml").write <<~EOS
      heartbeat.monitors:
      - type: tcp
        schedule: '@every 5s'
        hosts: ["localhost:#{port}"]
        check.send: "r u there\\n"
        check.receive: "i am here\\n"
      output.file:
        path: "#{testpath}/heartbeat"
        filename: heartbeat
        codec.format:
          string: '%{[monitor]}'
    EOS
    pid = fork do
      exec bin/"heartbeat", "-path.config", testpath/"config", "-path.data",
                            testpath/"data"
    end
    sleep 5

    t = nil
    begin
      t = Thread.new do
        loop do
          client = server.accept
          line = client.readline
          if line == "r u there\n"
            client.puts("i am here\n")
          else
            client.puts("goodbye\n")
          end
          client.close
        end
      end
      sleep 5
      assert_match "\"status\":\"up\"", (testpath/"heartbeat/heartbeat").read
    ensure
      Process.kill "SIGINT", pid
      Process.wait pid
      t.exit
      server.close
    end
  end
end
