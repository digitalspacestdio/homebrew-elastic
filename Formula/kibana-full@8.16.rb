class KibanaFullAT816 < Formula
  desc "Analytics and search dashboard for Elasticsearch"
  homepage "https://www.elastic.co/products/kibana"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/kibana/kibana-8.16.6-linux-aarch64.tar.gz"
      sha256 "2a0a089dba41bc470557c6ffa7666e598ac7d70c8f5e30c0f55cab545cdd2ea0"
    else
      url "https://artifacts.elastic.co/downloads/kibana/kibana-8.16.6-linux-x86_64.tar.gz"
      sha256 "eb2fcd2b4a7d8795dbec85c1fc05736759aad78898c3aadfb6ba5a700dc0e479"
    end
  else
    if Hardware::CPU.arm?
      url "https://artifacts.elastic.co/downloads/kibana/kibana-8.16.6-darwin-aarch64.tar.gz"
      sha256 "08e151deb34fc69d24a5ef56ee7438fb043f383ce7635806cb81d66551bdfedb"
    else
      url "https://artifacts.elastic.co/downloads/kibana/kibana-8.16.6-darwin-x86_64.tar.gz"
      sha256 "b6189e6bc58196a0487719bd5e340b9629049cf55f5c902af999d758428f4432"
    end
  end
  #end-auto-replace
  conflicts_with "kibana"

  def install
    libexec.install(
      "bin",
      "config",
      "data",
      "node",
      "node_modules",
      "package.json",
      "plugins",
      "src",
      "x-pack",
    )

    Pathname.glob(libexec/"bin/*") do |f|
      next if f.directory?
      bin.install libexec/"bin"/f
    end
    bin.env_script_all_files(libexec/"bin", { "KIBANA_PATH_CONF" => etc/"kibana", "DATA_PATH" => var/"lib/kibana/data" })

    cd libexec do
      packaged_config = IO.read "config/kibana.yml"
      IO.write "config/kibana.yml", "path.data: #{var}/lib/kibana/data\n" + packaged_config
      (etc/"kibana").install Dir["config/*"]
      rm_rf "config"
      rm_rf "data"
    end
  end

  def post_install
    (var/"lib/kibana/data").mkpath
    (prefix/"plugins").mkdir
  end

  def caveats; <<~EOS
    Config: #{etc}/kibana/
    If you wish to preserve your plugins upon upgrade, make a copy of
    #{opt_prefix}/plugins before upgrading, and copy it into the
    new keg location after upgrading.
  EOS
  end

  service do
    run [opt_bin/"kibana"]
    working_dir var
    log_path var/"log/kibana.log"
    error_log_path var/"log/kibana.log"
  end

  test do
    ENV["BABEL_CACHE_PATH"] = testpath/".babelcache.json"
    assert_match /#{version}/, shell_output("#{bin}/kibana -V")
  end
end
