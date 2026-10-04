#!/bin/sh
# Build the Vendetta Council OS Fedora ISO inside a fedora container.
# Needs docker (privileged) and ~15 GB free. Output: fedora/out/.
#
#   ./fedora/build-fedora-docker.sh
#
# Strategy: livecd-creator + Fedora's own KDE live kickstart (reused for its
# livesys autologin), Anaconda swapped for Calamares, Vendetta overlay injected.
# Calamares clones the live base rootfs (unpackfs /dev/mapper/live-base), so the
# installed system IS the live system — all theme/tool/branding assets carry over.
set -e
cd "$(dirname "$0")"
REPO="$(cd .. && pwd)"

exec docker run --rm --privileged \
	--network "${DOCKER_NET:-host}" \
	-v "$REPO:/repo" -w /repo/fedora \
	-e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
	fedora:43 bash -euo pipefail -c '
		trap "chown -R \"$HOST_UID:$HOST_GID\" /repo/fedora 2>/dev/null || true" EXIT

		# livecd-creator loop-mounts its rootfs image; a privileged container
		# still needs the loop module loaded (on the host kernel) and the device
		# nodes present in its own /dev.
		modprobe loop 2>/dev/null || true
		[ -e /dev/loop-control ] || mknod -m660 /dev/loop-control c 10 237 2>/dev/null || true
		for i in 0 1 2 3 4 5 6 7 8 9 10 11; do
			[ -e "/dev/loop$i" ] || mknod -m660 "/dev/loop$i" b 7 "$i" 2>/dev/null || true
		done

		dnf install -y livecd-tools rsync util-linux git

		# Fedora live kickstarts are not packaged — clone them (f43) so our
		# vendetta.ks can %include fedora-live-kde.ks and its chain.
		rm -rf /tmp/fk
		git clone -b f43 https://pagure.io/fedora-kickstarts.git /tmp/fk
		cp /repo/fedora/vendetta.ks /tmp/fk/vendetta.ks

		# --- assemble the overlay the kickstart injects (/tmp/overlay) ---
		rm -rf /tmp/overlay; mkdir -p /tmp/overlay
		# shared branding/theme/skel/toolkit from the Debian tree (reuses the
		# Arch asset copier; it stages a few package-owned files under
		# root/overlay — flatten them to final paths since Fedora injects the
		# overlay AFTER packages are installed, where overwriting is free).
		sh /repo/arch/copy-shared-assets.sh /tmp/overlay
		if [ -d /tmp/overlay/root/overlay ]; then
			cp -a /tmp/overlay/root/overlay/. /tmp/overlay/
			rm -rf /tmp/overlay/root/overlay
		fi
		# Fedora-specific files (Calamares config, os-release, greeter configs,
		# scripts, installer launcher, polkit rule).
		cp -a /repo/fedora/overlay-extra/. /tmp/overlay/
		# vendetta-hook.sh runs at build time (theming, no network); spydir-setup
		# runs on FIRST BOOT (needs network) from /usr/local/lib/vendetta/.
		install -d /tmp/overlay/root /tmp/overlay/usr/local/lib/vendetta
		install -m 0755 /repo/arch/vendetta-hook.sh /tmp/overlay/root/
		install -m 0755 /repo/arch/spydir-setup.sh  /tmp/overlay/usr/local/lib/vendetta/spydir-setup.sh
		# Fedora symlinks /usr/local/sbin -> bin, so our scripts live in bin
		# (a real usr/local/sbin dir in the overlay cannot cp-a-merge onto the
		# symlink). The /usr/local/sbin/... paths in the configs resolve via it.
		chmod +x /tmp/overlay/usr/local/bin/vendetta-* \
			/tmp/overlay/usr/bin/vendetta-tools 2>/dev/null || true

		# --- build ---
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
