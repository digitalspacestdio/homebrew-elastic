class AuditbeatFullAT816 < Formula
  desc "Lightweight Shipper for Audit Data"
  homepage "https://www.elastic.co/products/beats/auditbeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.16.6-linux-arm64.tar.gz"
      sha256 "bf5a40325bb3d1b245a80ef683672d0e132015606f52400ab87f934c976bda93"
    else
      url "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.16.6-linux-x86_64.tar.gz"
      sha256 "bef0b6ca649795c1b00de37c4fde6b02e06d155013663e9e739ff7d4e169a1dc"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.16.6-darwin-aarch64.tar.gz"
      sha256 "72950aa3b3541958d2e47ed797832af20964e340ac3e75ae1dae6ac785d4cdf0"
    else
      url "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.16.6-darwin-x86_64.tar.gz"
      sha256 "415223ee99700c6ef092f4f3c7afe0952371ab26e188b13173d5bf8f5b2c1a39"
    end
  end
  #end-auto-replace
  conflicts_with "auditbeat"
  conflicts_with "auditbeat-oss"

  def install
    ["fields.yml", "ingest", "kibana", "module"].each { |d| libexec.install d if File.exist?(d) }
    (libexec/"bin").install "auditbeat"
    (etc/"auditbeat").install "auditbeat.yml"
    (etc/"auditbeat").install "modules.d" if File.exist?("modules.d")

    (bin/"auditbeat").write <<~EOS
      #!/bin/sh
      exec #{libexec}/bin/auditbeat \
        --path.config #{etc}/auditbeat \
        --path.data #{var}/lib/auditbeat \
        --path.home #{libexec} \
        --path.logs #{var}/log/auditbeat \
        "$@"
    EOS
  end

  def post_install
    (var/"lib/auditbeat").mkpath
    (var/"log/auditbeat").mkpath
  end

  plist_options :manual => "auditbeat"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{opt_bin}/auditbeat</string>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    (testpath/"files").mkpath
    (testpath/"config/auditbeat.yml").write <<~EOS
      auditbeat.modules:
      - module: file_integrity
        paths:
          - #{testpath}/files
      output.file:
        path: "#{testpath}/auditbeat"
        filename: auditbeat
    EOS
    pid = fork do
      exec "#{bin}/auditbeat", "-path.config", testpath/"config", "-path.data", testpath/"data"
    end
    sleep 20

    begin
      touch testpath/"files/touch"
      sleep 30
      s = IO.readlines(testpath/"auditbeat/auditbeat").last(1)[0]
      assert_match "\"action\":\[\"created\"\]", s
      realdirpath = File.realdirpath(testpath)
      assert_match "\"path\":\"#{realdirpath}/files/touch\"", s
    ensure
      Process.kill "SIGINT", pid
      Process.wait pid
    end
  end
end
