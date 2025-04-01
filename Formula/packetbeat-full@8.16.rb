class PacketbeatFullAT816 < Formula
  desc "Lightweight Shipper for Network Data"
  homepage "https://www.elastic.co/products/beats/packetbeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.16.6-linux-arm64.tar.gz"
        sha512 "3a7e9b2977dff27c26e9c71acce30a1cb9ebab4326825a23c452ba675e3ee1e09310695352bb90221ee675999bef0152a27d92b3e370b762189977e61ad810d6"
      else
        url "https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.16.6-linux-x86_64.tar.gz"
        sha512 "b3eab5c61ed8017cdf793597ac7ecb99a9114f125def1739a87c55724b243d2fc18ecb3eef84f815646b2ec030d32cc5f6854182deda9dd2859d5c398b19faef"
      end
    else
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.16.6-darwin-aarch64.tar.gz"
        sha512 "4ff7e146044ee6169c565b642763de54085b8389d9bf2353684800282f7940d445134f8b7410bcd1e96f7ac2389eaa7c1d88c8516f66af7d2fe295ade8af435d"
      else
        url "https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-8.16.6-darwin-x86_64.tar.gz"
        sha512 "819b174c0ec59e95f606a25ea9214e812796361a70384cd8f4fb9370b6fc6cc2323c2299e79de51508417e825f4cbf0d2186cd8b2d8e1200b3f9c4b183a29e8c"
      end
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
