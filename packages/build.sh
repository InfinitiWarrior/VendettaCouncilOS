#!/bin/sh
set -e
cd "$(dirname "$0")"

command -v dpkg-buildpackage >/dev/null || { echo "need dpkg-dev:  apt install dpkg-dev debhelper"; exit 1; }

( cd vendetta-desktop && dpkg-buildpackage -b -us -uc )

mkdir -p ../config/packages.chroot
mv vendetta-desktop_*_all.deb ../config/packages.chroot/
rm -f vendetta-desktop_*.buildinfo vendetta-desktop_*.changes
echo "metapackage -> config/packages.chroot/"
