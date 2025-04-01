class KibanaFullAT816 < Formula
  desc "Analytics and search dashboard for Elasticsearch"
  homepage "https://www.elastic.co/products/kibana"
  #start-auto-replace
  version "8.16.6"
  if OS.linux?
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/kibana/kibana-8.16.6-linux-aarch64.tar.gz"
        sha512 "8f6b25e2f5c5938cf5d9a34e1615d9e1d5a29551ac0d5c70769d4915bc12110df852dbb157a3319e4dcd6e978a80ea12a1d97e373550ff4d6ca41dd0120a0089"
      else
        url "https://artifacts.elastic.co/downloads/kibana/kibana-8.16.6-linux-x86_64.tar.gz"
        sha512 "b79a4f2f7adf2d6fda4f1e82923066a7dce48ee6494e9349beaa4b78960ffc4dbed914b7acde8ec5e91aae3f8cbdfb54388b565984c054f709e5eafd9e201d9f"
      end
    else
      if Hardware::CPU.arm?
        url "https://artifacts.elastic.co/downloads/kibana/kibana-8.16.6-darwin-aarch64.tar.gz"
        sha512 "f2c52368b5794835030972e53fe57f9557ec2e7bf859c12e345a3aeb6e8d9040f33d853aad6b0f9b3da02b74a5f96009fcea74bfb0cb65b97ef8571466e55b8f"
      else
        url "https://artifacts.elastic.co/downloads/kibana/kibana-8.16.6-darwin-x86_64.tar.gz"
        sha512 "cfd275c0e07671b02657a54f79521a8b1d6f88e1b4b867c5f627f7f78282421e8f159c92a4e6d8bc8ca3bd78212b42351740d97971f20ecfdda31e639626a9b0"
      end
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
