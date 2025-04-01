class MetricbeatFullAT816 < Formula
  desc "Collect metrics from your systems and services"
  homepage "https://www.elastic.co/products/beats/metricbeat"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.16.6-linux-arm64.tar.gz"
      sha256 "0024ef17863523e03293278d434d46952d14e4d2ab68fbcad01566d94f4512da"
    else
      url "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.16.6-linux-x86_64.tar.gz"
      sha256 "403dd1a60107564582651a5587a8171e08f2b03575be5a78dacb393f534ffe44"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.16.6-darwin-aarch64.tar.gz"
      sha256 "11202967ec39e6f633d5837082ff11b5f0bbd3d984d30b80071e7596592ebb88"
    else
      url "https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.16.6-darwin-x86_64.tar.gz"
      sha256 "f1164f5f2caa5cc41a45a2f2d6e6cab3695ccdbcbbe3ecd7c9fed1a94bd28fc3"
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
