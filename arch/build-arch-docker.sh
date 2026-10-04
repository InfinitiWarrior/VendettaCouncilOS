#!/bin/sh
# Build the Vendetta Council OS Arch ISO inside an archlinux container.
# Needs docker (privileged) and ~15 GB free. Output lands in arch/out/.
#
#   ./arch/build-arch-docker.sh
#
# Strategy: start from archiso's stock `releng` profile and overlay our bits
# (airootfs, packages, pacman.conf, Calamares config, branding, live setup).
# The installer clones the live squashfs (Calamares unpackfs), so the installed
# system is the live system — every theme/tool/branding asset carries over.
set -e
cd "$(dirname "$0")"
REPO="$(cd .. && pwd)"

exec docker run --rm --privileged \
	--network "${DOCKER_NET:-host}" \
	-v "$REPO:/repo" -w /repo/arch \
	-e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
	archlinux:latest bash -euo pipefail -c '
		trap "chown -R \"$HOST_UID:$HOST_GID\" /repo/arch 2>/dev/null || true" EXIT

		pacman -Syu --noconfirm --needed archiso git rsync
		# make sure the host keyring is populated for core/extra verification
		pacman-key --init
		pacman-key --populate archlinux

		# --- assemble the profile: releng + our overlay ---
		PROFILE=/tmp/vendetta-arch
		rm -rf "$PROFILE"
		cp -r /usr/share/archiso/configs/releng "$PROFILE"

		# our airootfs (Calamares config, scripts, live configs, os-release)
		cp -a airootfs/. "$PROFILE/airootfs/"
		# shared branding/theme/skel/toolkit assets from the Debian tree
		sh copy-shared-assets.sh "$PROFILE/airootfs"

		# packages + pacman repo
		cat packages.x86_64.extra >> "$PROFILE/packages.x86_64"
		cat pacman-extra.conf     >> "$PROFILE/pacman.conf"

		# live-session setup appended to releng customize_airootfs.sh
		install -m 0755 vendetta-hook.sh spydir-setup.sh "$PROFILE/airootfs/root/"
		cat customize-append.sh >> "$PROFILE/airootfs/root/customize_airootfs.sh"

		# rebrand ISO metadata + boot menu text
		sed -i \
			-e "s/^iso_name=.*/iso_name=\"vendetta\"/" \
			-e "s/^iso_label=.*/iso_label=\"VENDETTA\"/" \
			-e "s/^iso_publisher=.*/iso_publisher=\"Vendetta Council\"/" \
			-e "s/^iso_application=.*/iso_application=\"Vendetta Council OS Live\"/" \
			"$PROFILE/profiledef.sh"
		grep -rl "Arch Linux" "$PROFILE/efiboot" "$PROFILE/syslinux" "$PROFILE/grub" 2>/dev/null \
			| xargs -r sed -i "s/Arch Linux/Vendetta Council OS/g"

		# ensure our scripts are executable inside the airootfs
		chmod +x "$PROFILE"/airootfs/usr/local/sbin/vendetta-* \
			"$PROFILE"/airootfs/usr/local/bin/vendetta-install \
			"$PROFILE"/airootfs/usr/bin/vendetta-tools 2>/dev/null || true

		rm -rf out work
		mkdir -p out
		mkarchiso -v -w work -o out "$PROFILE"
		mv out/*.iso out/vendetta-arch-amd64.iso 2>/dev/null || true
		echo "=== ISO ready: arch/out/ ==="
		ls -lh out
	'
