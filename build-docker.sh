#!/bin/sh
# Build the ISO inside a Debian container — for non-Debian hosts and CI.
# Needs docker and ~15 GB free. Takes 20-40 min. Output lands in this dir.
set -e
cd "$(dirname "$0")"

# --network host: skip the bridge/veth pair (needs the `veth` kernel module,
# absent on some hosts -> "operation not supported"). The build only needs
# outbound apt, no isolation. Override with DOCKER_NET=bridge if you want it.
exec docker run --rm --privileged \
	--network "${DOCKER_NET:-host}" \
	-v "$PWD:/build" -w /build \
	-e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
	-e FULL_CLEAN="${FULL_CLEAN:-}" \
	debian:trixie sh -c '
		set -e
		# always hand the tree back to the user, even if the build fails
		trap "chown -R \"$HOST_UID:$HOST_GID\" /build" EXIT

		apt-get update
		apt-get install -y live-build dpkg-dev debhelper fakeroot ca-certificates

		# wipe build state from a previous (possibly interrupted) build, but
		# KEEP cache/ — the ~2 GB package download cache makes reruns ~2x faster.
		# Pass FULL_CLEAN=1 to also drop the cache.
		lb clean 2>/dev/null || true
		[ -n "$FULL_CLEAN" ] && { lb clean --purge 2>/dev/null || true; rm -rf cache; }
		rm -rf .build chroot binary config/binary config/bootstrap \
		       config/chroot config/common config/source \
		       config/package-lists/live.list.chroot chroot.* binary.*

		./build.sh
	'
