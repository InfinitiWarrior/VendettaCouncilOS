#!/bin/sh
set -e
cd "$(dirname "$0")"

command -v lb >/dev/null || { echo "no live-build here. On Debian: apt install live-build dpkg-dev debhelper. Elsewhere: ./build-docker.sh"; exit 1; }

./packages/build.sh
lb clean
lb config
lb build

ls -1 live-image-*.hybrid.iso 2>/dev/null || { echo "no ISO produced — check build.log"; exit 1; }
