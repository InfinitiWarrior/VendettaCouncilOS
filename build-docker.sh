#!/bin/sh
set -e
cd "$(dirname "$0")"

exec docker run --rm --privileged \
	--network "${DOCKER_NET:-host}" \
	-v "$PWD:/build" -w /build \
	-e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
	-e FULL_CLEAN="${FULL_CLEAN:-}" \
	debian:trixie sh -c '
		set -e
		trap "chown -R \"$HOST_UID:$HOST_GID\" /build" EXIT

		apt-get update
		apt-get install -y live-build dpkg-dev debhelper fakeroot ca-certificates

		lb clean 2>/dev/null || true
		[ -n "$FULL_CLEAN" ] && { lb clean --purge 2>/dev/null || true; rm -rf cache; }
		rm -rf .build chroot binary config/binary config/bootstrap \
		       config/chroot config/common config/source \
		       config/package-lists/live.list.chroot chroot.* binary.*

		./build.sh
	'
