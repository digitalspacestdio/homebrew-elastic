class PacketbeatFullAT816 < Formula
  desc "Lightweight Shipper for Network Data"
  homepage "https://www.elastic.co/products/beats/packetbeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.16.6-linux-arm64.tar.gz"
      sha256 "49dc6b1556c672469e230ba172bb20eea2e82dacddd2bdbf4f675d26b416661b"
    else
      url "https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.16.6-linux-x86_64.tar.gz"
      sha256 "bc5a16c40c0dfc90bb25da6bb867afd3757ec53bd72c3e89024ea92ca86d0b3e"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.16.6-darwin-aarch64.tar.gz"
      sha256 "f7b3e10c577b32dd0d6d68ebe4ed0d9e50ea9090b47c088b1382ff139de3bfb7"
    else
      url "https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.16.6-darwin-x86_64.tar.gz"
      sha256 "2048efcb734a64e00cded4e1cfd00ed9253cd21ab9f0e3ae966a57bbbb52d5e6"
    end
  end
  #end-auto-replace
  conflicts_with "packetbeat"
  conflicts_with "packetbeat-oss"

  def install
    ["fields.yml", "ingest", "kibana", "module"].each { |d| libexec.install d if File.exist?(d) }
    (libexec/"bin").install "packetbeat"
    (etc/"packetbeat").install "packetbeat.yml"
    (etc/"packetbeat").install "modules.d" if File.exist?("modules.d")

    (bin/"packetbeat").write <<~EOS
      #!/bin/sh
      exec #{libexec}/bin/packetbeat \
        --path.config #{etc}/packetbeat \
        --path.data #{var}/lib/packetbeat \
        --path.home #{libexec} \
        --path.logs #{var}/log/packetbeat \
        "$@"
    EOS
  end

  plist_options :manual => "packetbeat"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{opt_bin}/packetbeat</string>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    system "#{bin}/packetbeat", "devices"
  end
end
