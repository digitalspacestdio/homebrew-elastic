class LogstashFullAT816 < Formula
  desc "Tool for managing events and logs"
  homepage "https://www.elastic.co/products/logstash"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/logstash/logstash-8.16.6-linux-aarch64.tar.gz"
      sha256 "a0ddb3550f14a195025b897e557b1b9a0af879c6dcf8d249c0080b021d62e6aa"
    else
      url "https://artifacts.elastic.co/downloads/logstash/logstash-8.16.6-linux-x86_64.tar.gz"
      sha256 "5f1bbc99779e784cdd18c8a23f134d9ba2d32dda7a4a288eebdd55f3bc11c746"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/logstash/logstash-8.16.6-darwin-aarch64.tar.gz"
      sha256 "aa68e011ced0ba61b0d0e7636aca364b38cf56a7d3162ad47ad6a07e251a5e55"
    else
      url "https://artifacts.elastic.co/downloads/logstash/logstash-8.16.6-darwin-x86_64.tar.gz"
      sha256 "7b37b031a0431297fc94e17fee54d79b272eaf712a256d7f64d6b021aac59a18"
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
