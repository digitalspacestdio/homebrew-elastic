class ElasticsearchFullAT816 < Formula
  desc "Distributed search & analytics engine"
  homepage "https://www.elastic.co/products/elasticsearch"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.16.6-linux-aarch64.tar.gz"
      sha256 "189bad46928bc01cfe5090ff784340bc187b1b8f0a03528aecebe1575859691d"
    else
      url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.16.6-linux-x86_64.tar.gz"
      sha256 "308a5ef379550fd5c8d65b77052f2fc2efabc124a98c4bbc2c89a84ce82b781d"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.16.6-darwin-aarch64.tar.gz"
      sha256 "3c37b438ba83003ec869337c8806d638fb831e86ed487dc3d8ef70ac77adba69"
    else
      url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.16.6-darwin-x86_64.tar.gz"
      sha256 "b17aa116ab28a6f9d64e0520687e01f4afd8de3ab25ad1c6a307e626725e1355"
    end
  end
  #end-auto-replace
  conflicts_with "elasticsearch"

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
      s.insert(s.length, "\nxpack.security.enabled: false\n") unless s.to_s.include?("xpack.security.enabled")
    end

    inreplace "#{libexec}/config/jvm.options", %r{logs/gc.log}, "#{var}/log/#{name}/gc.log"

    # Replace or insert heap settings for development
    inreplace "#{libexec}/config/jvm.options" do |s|
      s.gsub!(/^(-Xms).*$/, "\\1 128m") unless s.to_s.include?("-Xms128m")
      s.gsub!(/^(-Xmx).*$/, "\\1 1g") unless s.to_s.include?("-Xmx1g")
    end

    # Move config files into etc
    (etc/"#{name}").install Dir[libexec/"config/*"]
    (libexec/"config").rmtree

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
    log_path var/"log/elasticsearch-full@8.16.log"
    error_log_path var/"log/elasticsearch-full@8.16.log"
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
