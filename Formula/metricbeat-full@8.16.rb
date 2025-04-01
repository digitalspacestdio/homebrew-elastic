class MetricbeatFullAT816 < Formula
  desc "Collect metrics from your systems and services"
  homepage "https://www.elastic.co/products/beats/metricbeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.16.6-linux-arm64.tar.gz"
        sha512 "54eca333d8b43e76ffbf44e5fcd863bf0628fcd032a01778ab4f478b4e554160be328834727ab79e02af1d992c9e595d19a9e9a4d3918a65b073c7c30a55002c"
      else
        url "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.16.6-linux-x86_64.tar.gz"
        sha512 "3d712667279a8c6dc2c6bfa00fbe440171d8a320fa92cb00527a70b883039d96cfca207d0361389e928fbf2d1458074eddce97277c5823bcc8050d0da8f603de"
      end
    else
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.16.6-darwin-aarch64.tar.gz"
        sha512 "ddf3de0f90cd4704116bca4bc5df7de016c5b0fb02c9192c37f75a9ae8f3037956bff24bd49456f394518b13d0563eb21f1f5def4785d21c3af602cc467c9594"
      else
        url "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.16.6-darwin-x86_64.tar.gz"
        sha512 "990f676ce319f3df4dc74b1c17c3446c496c4923152b24d382d1de7d33588360031e3324f4a1ce35f1c6b42596ae1054e0bdb79d2f5d332a129161d0adac4c3a"
      end
    end
  end
  #end-auto-replace
  conflicts_with "metricbeat"
  conflicts_with "metricbeat-oss"

  def install
    ["fields.yml", "ingest", "kibana", "module"].each { |d| libexec.install d if File.exist?(d) }
    (libexec/"bin").install "metricbeat"
    (etc/"metricbeat").install "metricbeat.yml"
    (etc/"metricbeat").install "modules.d" if File.exist?("modules.d")

    (bin/"metricbeat").write <<~EOS
      #!/bin/sh
      exec #{libexec}/bin/metricbeat \
        --path.config #{etc}/metricbeat \
        --path.data #{var}/lib/metricbeat \
        --path.home #{libexec} \
        --path.logs #{var}/log/metricbeat \
        "$@"
    EOS
  end

  plist_options :manual => "metricbeat"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{opt_bin}/metricbeat</string>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    (testpath/"config/metricbeat.yml").write <<~EOS
      metricbeat.modules:
      - module: system
        metricsets: ["load"]
        period: 1s
      output.file:
        enabled: true
        path: #{testpath}/data
        filename: metricbeat
    EOS

    (testpath/"logs").mkpath
    (testpath/"data").mkpath

    pid = fork do
      exec bin/"metricbeat", "-path.config", testpath/"config", "-path.data",
                             testpath/"data"
    end

    begin
      sleep 30
      assert_predicate testpath/"data/metricbeat", :exist?
    ensure
      Process.kill "SIGINT", pid
      Process.wait pid
    end
  end
end
