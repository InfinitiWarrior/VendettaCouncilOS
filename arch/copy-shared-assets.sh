#!/bin/sh
# Copy the distro-agnostic Vendetta assets from the Debian tree
# (../config/includes.chroot) into the Arch airootfs, so both ISOs ship byte-for
# -byte identical branding/theme/skel. Usage: copy-shared-assets.sh <airootfs-dir>
set -eu
DEST="$1"
SRC="$(cd "$(dirname "$0")/../config/includes.chroot" && pwd)"

# Files + directories reused verbatim (same relative path in the target).
PATHS="
usr/share/aurorae/themes/Vendetta
usr/share/Kvantum/Vendetta
usr/share/plasma/desktoptheme/Vendetta
usr/share/plasma/look-and-feel/org.vendetta.desktop
usr/share/fonts/truetype/chakra-petch
usr/share/sddm/themes/vendetta
usr/share/plymouth/themes/vendetta
usr/share/wallpapers/Vendetta
usr/share/konsole
usr/share/icons/hicolor
usr/share/fastfetch/logos
usr/share/color-schemes/Vendetta.colors
usr/share/vendetta/sigil.png
usr/lib/vendetta-apply-theme
usr/lib/vendetta-seed-avatar
usr/local/bin/spydir-webapp
etc/skel/.config/fastfetch
etc/skel/.config/hypr
etc/skel/.config/i3
etc/skel/.config/i3status
etc/skel/.config/Kvantum
etc/skel/.config/mako
etc/skel/.config/rofi
etc/skel/.config/sway
etc/skel/.config/waybar
etc/skel/.config/wofi
etc/skel/.config/picom.conf
etc/xdg/gtk-3.0
etc/xdg/gtk-4.0
etc/xdg/kitty
etc/xdg/xfce4
etc/dconf
etc/sddm.conf.d/10-vendetta.conf
etc/xdg/autostart/vendetta-apply-theme.desktop
etc/systemd/system/vendetta-avatar.service
etc/sysctl.d/99-vendetta.conf
etc/udev/rules.d/60-vendetta-ioschedulers.rules
etc/systemd/journald.conf.d/vendetta.conf
usr/share/applications/spydir-opsec.desktop
usr/share/applications/spydir-os.desktop
usr/share/applications/spy-geoint.desktop
usr/share/applications/spy-kernel-triage.desktop
usr/share/applications/spy-osint-suite.desktop
usr/share/applications/spy-privacy-pulse.desktop
usr/share/applications/spy-recon-mapper.desktop
usr/share/applications/spy-threat-hunt.desktop
"

cd "$SRC"
for p in $PATHS; do
	[ -e "$p" ] || { echo "W: missing shared asset $p"; continue; }
	cp -a --parents "$p" "$DEST/"
done

# GRUB background for the installed system (Calamares grubcfg points here).
install -Dm644 "$SRC/boot/grub/vendetta.png" "$DEST/usr/share/vendetta/grub-bg.png"

# These paths are owned by the `filesystem`/`calamares` packages, so they can't
# sit in the airootfs (pacstrap would abort on "exists in filesystem"). Stage
# them under /root/overlay; customize_airootfs.sh copies them onto / AFTER
# pacstrap, where overwriting package files is free.
OV="$DEST/root/overlay"
install -Dm644 "$SRC/etc/issue" "$OV/etc/issue"
install -Dm644 "$SRC/etc/motd"  "$OV/etc/motd"
# Calamares branding logos (reuse the Debian ones under our vendetta branding).
BR="$OV/etc/calamares/branding/vendetta"
install -Dm644 "$SRC/etc/calamares/branding/debian/vendetta-logo.png" "$BR/vendetta-logo.png"
install -Dm644 "$SRC/etc/calamares/branding/debian/welcome.png"       "$BR/welcome.png"

echo "shared assets copied into $DEST"
