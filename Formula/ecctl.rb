# This file was generated by GoReleaser. DO NOT EDIT.
class Ecctl < Formula
  desc "Elastic Cloud Control, the official Elastic Cloud and ECE command line interface"
  homepage "https://github.com/elastic/ecctl"
  version "1.14.2"

  if OS.mac?
    url "https://download.elastic.co/downloads/ecctl/1.14.2/ecctl_1.14.2_darwin_amd64.tar.gz", :using => CurlDownloadStrategy
    sha256 "3adfefc7a4eab7bb09bee212e830fb6ad9d3b9fcc68bd917bfb4744b2808712f"
  elsif OS.linux?
    url "https://download.elastic.co/downloads/ecctl/1.14.2/ecctl_1.14.2_linux_amd64.tar.gz", :using => CurlDownloadStrategy
    sha256 "8304596e0dc7ac15531680837bbc9af4f07838ad8c9bd71d9471422cbf875b6e"
  end

  def install
    bin.install "ecctl"
    system "#{bin}/ecctl", "generate", "completions", "-l", "#{var}/ecctl.auto"
  end

  def caveats; <<~EOS
    To get autocompletions working make sure to run "source <(ecctl generate completions)".
    If you prefer to add to your shell interpreter configuration file run, for bash or zsh respectively:
    * `echo "source <(ecctl generate completions)" >> ~/.bash_profile`
    * `echo "source <(ecctl generate completions)" >> ~/.zshrc`.
  EOS
  end

  test do
    system "#{bin}/ecctl version"
  end
end
