class HeartbeatFullAT816 < Formula
  desc "Lightweight Shipper for Uptime Monitoring"
  homepage "https://www.elastic.co/products/beats/heartbeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.16.6-linux-arm64.tar.gz"
      sha256 "beb54739c0e18b5a9c5dc77140abb675dfb054203de0b29e8b068d0008386626"
    else
      url "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.16.6-linux-x86_64.tar.gz"
      sha256 "fad200bbbeb82f78ec362c8f73f46b0338a15006cd92776ca4b9f8b9939ec2e8"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.16.6-darwin-aarch64.tar.gz"
      sha256 "7c1de476aa5fc1c0565d6c16f39af7fd60c1054b786f3643de8e78d50d4e9f1a"
    else
      url "https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-8.16.6-darwin-x86_64.tar.gz"
      sha256 "fdce34ca35438e6165a51ee7b73150fc5d042395111e531c2261d589294eed6b"
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
