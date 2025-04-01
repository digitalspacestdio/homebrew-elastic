#!/usr/bin/env bash

set -euxo pipefail
OLD_PWD=$(pwd)
cd $(dirname $0)
export DIR=$(pwd)

while read MINOR_VERSION; do
  APP=("elasticsearch-full" "kibana-full" "logstash-full")
  OS=("linux" "darwin")
  ARCH=("x86_64" "aarch64")
  VERSION=$(pup '#content li.listitem a text{}' -f <(curl -s https://www.elastic.co/guide/en/elasticsearch/reference/$MINOR_VERSION/es-release-notes.html) | grep $MINOR_VERSION | grep -o '[0-9]\+.[0-9]\+.[0-9]\+' | head -1 || true)
  for app in "${APP[@]}"; do
    if [ -f ${DIR}/../Formula/$app@$MINOR_VERSION.rb ]; then
      if [ -z "$VERSION" ]; then
        echo "No link found for version $MINOR_VERSION"
        continue
      fi
      echo "Updating to version $VERSION"

      LINUX_AARCH64_URL=$(pup 'a:contains("Linux aarch64") attr{href}' -f <(curl https://www.elastic.co/downloads/past-releases/$(echo $app | awk -F- '{ print $1 }')-$(echo $VERSION | sed s~\\.~-~g)))
      LINUX_AARCH64_SHA256=$(curl -s $LINUX_AARCH64_URL | shasum -a 256 | awk '{ print $1 }')
      LINUX_X86_64_URL=$(pup 'a:contains("Linux x86_64") attr{href}' -f <(curl https://www.elastic.co/downloads/past-releases/$(echo $app | awk -F- '{ print $1 }')-$(echo $VERSION | sed s~\\.~-~g)))
      LINUX_X86_64_SHA256=$(curl -s $LINUX_X86_64_URL | shasum -a 256 | awk '{ print $1 }')
      MACOS_AARCH64_URL=$(pup 'a:contains("macOS aarch64") attr{href}' -f <(curl https://www.elastic.co/downloads/past-releases/$(echo $app | awk -F- '{ print $1 }')-$(echo $VERSION | sed s~\\.~-~g)))
      MACOS_AARCH64_SHA256=$(curl -s $MACOS_AARCH64_URL | shasum -a 256 | awk '{ print $1 }')
      MACOS_X86_64_URL=$(pup 'a:contains("macOS x86_64") attr{href}' -f <(curl https://www.elastic.co/downloads/past-releases/$(echo $app | awk -F- '{ print $1 }')-$(echo $VERSION | sed s~\\.~-~g)))
      MACOS_X86_64_SHA256=$(curl -s $MACOS_X86_64_URL | shasum -a 256 | awk '{ print $1 }')
      export CONFIG='#start-auto-replace
  version "'$VERSION'"
  if OS.linux?
    if Hardware::CPU.arm?
      url "'$LINUX_AARCH64_URL'"
      sha256 "'$LINUX_AARCH64_SHA256'"
    else
      url "'$LINUX_X86_64_URL'"
      sha256 "'$LINUX_X86_64_SHA256'"
    end
  else
    if Hardware::CPU.arm?
      url "'$MACOS_AARCH64_URL'"
      sha256 "'$MACOS_AARCH64_SHA256'"
    else
      url "'$MACOS_X86_64_URL'"
      sha256 "'$MACOS_X86_64_SHA256'"
    end
  end
  #end-auto-replace'

      perl -i -p0e 's/#start-auto-replace.*?\#end-auto-replace/'\$ENV{"CONFIG"}'/s' ${DIR}/../Formula/$app@$MINOR_VERSION.rb
    fi
  done

  sleep 1
done < <(pup '#content p a.ulink text{}' -f <(curl -s https://www.elastic.co/guide/en/starting-with-the-elasticsearch-platform-and-its-solutions/8.17/new.html))
cd $OLD_PWD
