class AuditbeatFullAT816 < Formula
  desc "Lightweight Shipper for Audit Data"
  homepage "https://www.elastic.co/products/beats/auditbeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.16.6-linux-arm64.tar.gz"
        sha512 "ba63ef1523afc14fef89d030bfd60b3b028f09a9249fa3c2e5a8ce2f7d756c8dbefa04abd6ce343173476c28b395ebcf4e29f62801d2a62af684f08c95bb807c"
      else
        url "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.16.6-linux-x86_64.tar.gz"
        sha512 "dbedbd866e233b6a3402dee776cf313a92e85a2d60c8ce3573f26fe401db7148dee69fbc0854292894f0beb62b23ae24f986e727a26819f413aacd8c45a080e4"
      end
    else
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.16.6-darwin-aarch64.tar.gz"
        sha512 "1f08d2d7ecabf830149ef37a54feddacff0e1670cb46fef9427a5f81be916e8a390aab39c0d440cc0ad33cd8f2b2320d73b945e451edaa248bff7611d9b78d86"
      else
        url "https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-8.16.6-darwin-x86_64.tar.gz"
        sha512 "52a253606e4b00b248f3ad5e2d3e20635cdfc10298f49eeb0b4eb2f1acc92b30a3c85716c37abef12b0f05de738fa6a09f18dee6c9f031b314aa42fc5400b81a"
      end
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
