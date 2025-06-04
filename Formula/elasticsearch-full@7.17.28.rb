class ElasticsearchFullAT71728 < Formula
  desc "Distributed search & analytics engine"
  homepage "https://www.elastic.co/products/elasticsearch"
  #start-auto-replace
  version "7.17.28"
  revision 1
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.28-linux-aarch64.tar.gz"
      sha256 "98d43b9fa74f45960dc8c697bdecc9bee1e8424958f86fe5489748eace0e8ec5"
    else
      url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.28-linux-x86_64.tar.gz"
      sha256 "d72adef80b899eb624f6e14aa3b0d8c2ed6597e5fe328bbb1ed9de2c3c14ef28"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.28-darwin-aarch64.tar.gz"
      sha256 "c54fe211d6dc06df0383a06c4388f9fd112b0247b50afee4687885bfbafde0c8"
    else
      url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.28-darwin-x86_64.tar.gz"
      sha256 "50d4fe9ec4f30c0cf9bdf3c879e4d2d61d9bc188a7dc29a1eb64e94c74a13458"
    end
  end
  #end-auto-replace
  conflicts_with "elasticsearch-full@8.16.6"

  def cluster_name
    "#{name}_#{ENV["USER"]}"
  end

  def install
    # Install everything else into package directory
    libexec.install "bin", "config", "jdk.app", "lib", "modules"

    inreplace libexec/"bin/elasticsearch-env",
              "if [ -z \"$ES_PATH_CONF\" ]; then ES_PATH_CONF=\"$ES_HOME\"/config; fi",
              "if [ -z \"$ES_PATH_CONF\" ]; then ES_PATH_CONF=\"#{etc}/#{name}\"; fi"

    # Set up Elasticsearch for local development:
    inreplace "#{libexec}/config/elasticsearch.yml" do |s|
      # 1. Give the cluster a unique name
      s.gsub!(/#\s*cluster\.name\: .*/, "cluster.name: #{cluster_name}")
    
      # 2. Configure paths
      s.sub!(%r{#\s*path\.data: /path/to.+$}, "path.data: #{var}/lib/#{name}/")
      s.sub!(%r{#\s*path\.logs: /path/to.+$}, "path.logs: #{var}/log/#{name}/")
    
      # 3. Disable X-Pack security for local usage
      original = s.to_s
      unless original.include?("xpack.security.enabled")
        s.gsub!(/.*\z/, "#{original}\nxpack.security.enabled: false\n")
      end
    end

    inreplace "#{libexec}/config/jvm.options", %r{logs/gc.log}, "#{var}/log/#{name}/gc.log"

    # Replace or insert heap settings for development
    jvm_path = "#{libexec}/config/jvm.options"
    jvm_contents = File.read(jvm_path)
    
    # Ensure -Xms exists or is replaced
    unless jvm_contents.match?(/^-Xms/)
      jvm_contents << "\n-Xms128m\n"
    else
      jvm_contents.gsub!(/^-Xms.*$/, "-Xms128m")
    end
    
    # Ensure -Xmx exists or is replaced
    unless jvm_contents.match?(/^-Xmx/)
      jvm_contents << "\n-Xmx1g\n"
    else
      jvm_contents.gsub!(/^-Xmx.*$/, "-Xmx1g")
    end
    
    # Overwrite the file manually
    File.write(jvm_path, jvm_contents)


    # Move config files into etc
    (etc/"#{name}").install Dir[libexec/"config/*"]
    FileUtils.rm_r(libexec/"config")

    Dir.foreach(libexec/"bin") do |f|
      next if f == "." || f == ".." || !File.extname(f).empty?

      bin.install libexec/"bin"/f
    end
    bin.env_script_all_files(libexec/"bin", {})

    if OS.mac?
        if Hardware::CPU.arm?
            system "codesign", "-f", "-s", "-", "#{libexec}/modules/x-pack-ml/platform/darwin-aarch64/controller.app", "--deep"
            system "find", "#{libexec}/jdk.app/Contents/Home/bin", "-type", "f", "-exec", "codesign", "-f", "-s", "-", "{}", ";"
        else
            system "codesign", "-f", "-s", "-", "#{libexec}/modules/x-pack-ml/platform/darwin-x86_64/controller.app", "--deep"
            system "find", "#{libexec}/jdk.app/Contents/Home/bin", "-type", "f", "-exec", "codesign", "-f", "-s", "-", "{}", ";"
        end
    end
  end

  def supervisor_config_dir
    etc / "digitalspace-supervisor.d"
  end

  def supervisor_config_path
      supervisor_config_dir / "#{name}.ini"
  end

  def post_install
    # Make sure runtime directories exist
    (var/"lib/#{name}/#{cluster_name}").mkpath
    (var/"log/#{name}").mkpath
    ln_s etc/"#{name}", libexec/"config"
    (var/"#{name}/plugins").mkpath
    ln_s var/"#{name}/plugins", libexec/"plugins"

    supervisor_config =<<~EOS
      [program:#{name}]
      command=#{opt_bin}/elasticsearch
      directory=#{opt_bin}
      stdout_logfile=#{HOMEBREW_PREFIX}/var/log/digitalspace-supervisor-#{name}.log
      stdout_logfile_maxbytes=1MB
      stderr_logfile=#{HOMEBREW_PREFIX}/var/log/digitalspace-supervisor-#{name}.err
      stderr_logfile_maxbytes=1MB
      user=#{ENV['USER']}
      autorestart=true
      stopasgroup=true
    EOS

    supervisor_config_dir.mkpath
    File.delete supervisor_config_path if File.exist?(supervisor_config_path)
    supervisor_config_path.write(supervisor_config)
  end

  def caveats
    s = <<~EOS
      Data:    #{var}/lib/#{name}/#{cluster_name}/
      Logs:    #{var}/log/#{name}/#{cluster_name}.log
      Plugins: #{var}/#{name}/plugins/
      Config:  #{etc}/#{name}/
    EOS

    s
  end

  service do
    run [opt_bin/"elasticsearch"]
    working_dir var
    log_path var/"log/elasticsearch-full@7.17.28.log"
    error_log_path var/"log/elasticsearch-full@7.17.28.log"
  end

  test do
    require "socket"

    server = TCPServer.new(0)
    port = server.addr[1]
    server.close

    mkdir testpath/"config"
    cp etc/"#{name}/jvm.options", testpath/"config"
    cp etc/"#{name}/log4j2.properties", testpath/"config"
    touch testpath/"config/elasticsearch.yml"

    ENV["ES_PATH_CONF"] = testpath/"config"

    system "#{bin}/elasticsearch-plugin", "list"

    pid = testpath/"pid"
    begin
      system "#{bin}/elasticsearch", "-d", "-p", pid, "-Expack.security.enabled=false", "-Epath.data=#{testpath}/data", "-Epath.logs=#{testpath}/logs", "-Enode.name=test-cli", "-Ehttp.port=#{port}"
      sleep 30
      system "curl", "-XGET", "localhost:#{port}/"
      output = shell_output("curl -s -XGET localhost:#{port}/_cat/nodes")
      assert_match "test-cli", output
    ensure
      Process.kill(9, pid.read.to_i)
    end

    server = TCPServer.new(0)
    port = server.addr[1]
    server.close

    rm testpath/"config/elasticsearch.yml"
    (testpath/"config/elasticsearch.yml").write <<~EOS
      path.data: #{testpath}/data
      path.logs: #{testpath}/logs
      node.name: test-es-path-conf
      http.port: #{port}
    EOS

    pid = testpath/"pid"
    begin
      system "#{bin}/elasticsearch", "-d", "-p", pid, "-Expack.security.enabled=false"
      sleep 30
      system "curl", "-XGET", "localhost:#{port}/"
      output = shell_output("curl -s -XGET localhost:#{port}/_cat/nodes")
      assert_match "test-es-path-conf", output
    ensure
      Process.kill(9, pid.read.to_i)
    end
  end
end
