class LogstashFullAT816 < Formula
  desc "Tool for managing events and logs"
  homepage "https://www.elastic.co/products/logstash"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/logstash/logstash-8.16.6-linux-aarch64.tar.gz"
        sha512 "43fdd166d50538970de1598d562c313aa9bb60235baebe0ebd6b90fde1fe06034ef6e9ed79a7f1e549f9a3fbd22508c33f4764f32654dd8b8e4125c610b203d4"
      else
        url "https://artifacts.elastic.co/downloads/logstash/logstash-8.16.6-linux-x86_64.tar.gz"
        sha512 "36f6211ba08c3c16ac99598a46469589bf4676ab22b274e54f7b01d864db662d4a2b3ccf85ab7594f102fbe5ed471baeb410fb8eddd75a81409b7e0701c0c469"
      end
    else
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/logstash/logstash-8.16.6-darwin-aarch64.tar.gz"
        sha512 "e9d59316b10ece87063902ee95de570f1a498df2c2ef8df9f1de1d157689bc6524742ef89ab13c75086cc2b33ad5686765a69ca69076a929e3b23b83916ba8ea"
      else
        url "https://artifacts.elastic.co/downloads/logstash/logstash-8.16.6-darwin-x86_64.tar.gz"
        sha512 "2e42112cef6e1833397417641ccd4d9cd47da8e7d4ef99bea02898175a6b57e4ff065449ff5bd29d85bb3b46366402123bd633ee9ed0534af7e8f44bb8c8ba57"
      end
    end
  end
  #end-auto-replace
  conflicts_with "logstash"
  conflicts_with "logstash-oss"

  def install
    inreplace "bin/logstash",
              %r{^\. "\$\(cd `dirname \${SOURCEPATH}`\/\.\.; pwd\)\/bin\/logstash\.lib\.sh\"},
              ". #{libexec}/bin/logstash.lib.sh"
    inreplace "bin/logstash-plugin",
              %r{^\. "\$\(cd `dirname \$0`\/\.\.; pwd\)\/bin\/logstash\.lib\.sh\"},
              ". #{libexec}/bin/logstash.lib.sh"
    inreplace "bin/logstash.lib.sh",
              /^LOGSTASH_HOME=.*$/,
              "LOGSTASH_HOME=#{libexec}"

    libexec.install Dir["*"]

    # Move config files into etc
    (etc/"logstash").install Dir[libexec/"config/*"]
    (libexec/"config").rmtree

    bin.install libexec/"bin/logstash", libexec/"bin/logstash-plugin"
    bin.env_script_all_files(libexec/"bin", {})
    system "find", "#{libexec}/jdk.app/Contents/Home/bin", "-type", "f", "-exec", "codesign", "-f", "-s", "-", "{}", ";"
  end

  def post_install
    # Make sure runtime directories exist
    ln_s etc/"logstash", libexec/"config"
  end

  def caveats; <<~EOS
    Please read the getting started guide located at:
      https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html
  EOS
  end

  plist_options :manual => "logstash"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>KeepAlive</key>
          <false/>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_bin}/logstash</string>
          </array>
          <key>EnvironmentVariables</key>
          <dict>
          </dict>
          <key>RunAtLoad</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{var}</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/logstash.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/logstash.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    # workaround https://github.com/elastic/logstash/issues/6378
    (testpath/"config").mkpath
    ["jvm.options", "log4j2.properties", "startup.options"].each do |f|
      cp prefix/"libexec/config/#{f}", testpath/"config"
    end
    (testpath/"config/logstash.yml").write <<~EOS
      path.queue: #{testpath}/queue
    EOS
    (testpath/"data").mkpath
    (testpath/"logs").mkpath
    (testpath/"queue").mkpath

    data = "--path.data=#{testpath}/data"
    logs = "--path.logs=#{testpath}/logs"
    settings = "--path.settings=#{testpath}/config"

    output = pipe_output("#{bin}/logstash -e '' #{data} #{logs} #{settings} --log.level=fatal", "hello world\n")
    assert_match "hello world", output
  end
end
