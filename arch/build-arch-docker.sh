#!/bin/sh
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
		pacman-key --init
		pacman-key --populate archlinux

		PROFILE=/tmp/vendetta-arch
		rm -rf "$PROFILE"
		cp -r /usr/share/archiso/configs/releng "$PROFILE"

		cp -a airootfs/. "$PROFILE/airootfs/"
		sh copy-shared-assets.sh "$PROFILE/airootfs"

		cat packages.x86_64.extra >> "$PROFILE/packages.x86_64"
		cat pacman-extra.conf     >> "$PROFILE/pacman.conf"

		install -m 0755 vendetta-hook.sh spydir-setup.sh "$PROFILE/airootfs/root/"
		cat customize-append.sh >> "$PROFILE/airootfs/root/customize_airootfs.sh"

		sed -i \
			-e "s/^iso_name=.*/iso_name=\"vendetta\"/" \
			-e "s/^iso_label=.*/iso_label=\"VENDETTA\"/" \
			-e "s/^iso_publisher=.*/iso_publisher=\"Vendetta Council\"/" \
			-e "s/^iso_application=.*/iso_application=\"Vendetta Council OS Live\"/" \
			"$PROFILE/profiledef.sh"
		grep -rl "Arch Linux" "$PROFILE/efiboot" "$PROFILE/syslinux" "$PROFILE/grub" 2>/dev/null \
			| xargs -r sed -i "s/Arch Linux/Vendetta Council OS/g"

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
