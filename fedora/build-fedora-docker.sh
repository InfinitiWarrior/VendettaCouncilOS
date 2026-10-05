#!/bin/sh
set -e
cd "$(dirname "$0")"
REPO="$(cd .. && pwd)"

exec docker run --rm --privileged \
	--network "${DOCKER_NET:-host}" \
	-v "$REPO:/repo" -w /repo/fedora \
	-e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
	fedora:43 bash -euo pipefail -c '
		trap "chown -R \"$HOST_UID:$HOST_GID\" /repo/fedora 2>/dev/null || true" EXIT

		modprobe loop 2>/dev/null || true
		[ -e /dev/loop-control ] || mknod -m660 /dev/loop-control c 10 237 2>/dev/null || true
		for i in 0 1 2 3 4 5 6 7 8 9 10 11; do
			[ -e "/dev/loop$i" ] || mknod -m660 "/dev/loop$i" b 7 "$i" 2>/dev/null || true
		done

		dnf install -y livecd-tools rsync util-linux git

		rm -rf /tmp/fk
		git clone -b f43 https://pagure.io/fedora-kickstarts.git /tmp/fk
		cp /repo/fedora/vendetta.ks /tmp/fk/vendetta.ks

		rm -rf /tmp/overlay; mkdir -p /tmp/overlay
		sh /repo/arch/copy-shared-assets.sh /tmp/overlay
		if [ -d /tmp/overlay/root/overlay ]; then
			cp -a /tmp/overlay/root/overlay/. /tmp/overlay/
			rm -rf /tmp/overlay/root/overlay
		fi
		cp -a /repo/fedora/overlay-extra/. /tmp/overlay/
		install -d /tmp/overlay/root /tmp/overlay/usr/local/lib/vendetta
		install -m 0755 /repo/arch/vendetta-hook.sh /tmp/overlay/root/
		install -m 0755 /repo/arch/spydir-setup.sh  /tmp/overlay/usr/local/lib/vendetta/spydir-setup.sh
		chmod +x /tmp/overlay/usr/local/bin/vendetta-* \
			/tmp/overlay/usr/bin/vendetta-tools 2>/dev/null || true

		chown -R 0:0 /tmp/overlay

		rm -rf out; mkdir -p out; cd out
		livecd-creator --verbose \
			--config /tmp/fk/vendetta.ks \
			--fslabel Vendetta \
			--title "Vendetta Council OS" \
			--product "Vendetta Council OS" \
			--cache /var/cache/live
		mv -f Vendetta.iso vendetta-fedora-amd64.iso 2>/dev/null || true
		echo "=== ISO ready: fedora/out/ ==="
		ls -lh
	'
