#!/bin/sh
# Install the Vendetta Plasma theme for the current user and apply it.
# The ISO ships all of this system-wide already; this is for trying it on
# another distro or iterating during development.
set -e
cd "$(dirname "$0")/.."
SRC=config/includes.chroot/usr/share
DST="${XDG_DATA_HOME:-$HOME/.local/share}"

mkdir -p "$DST/color-schemes" "$DST/plasma/desktoptheme" "$DST/aurorae/themes" \
         "$DST/konsole" "$DST/wallpapers" "$DST/plasma/look-and-feel" \
         "$DST/Kvantum/Vendetta" "$HOME/.config/Kvantum" "$HOME/.fonts"

cp    "$SRC/color-schemes/Vendetta.colors"        "$DST/color-schemes/"
cp -r "$SRC/plasma/desktoptheme/Vendetta"         "$DST/plasma/desktoptheme/"
cp -r "$SRC/plasma/look-and-feel/org.vendetta.desktop" "$DST/plasma/look-and-feel/"
cp -r "$SRC/aurorae/themes/Vendetta"              "$DST/aurorae/themes/"
cp    "$SRC/konsole/Vendetta.profile" "$SRC/konsole/Vendetta.colorscheme" "$DST/konsole/"
cp -r "$SRC/wallpapers/Vendetta"                  "$DST/wallpapers/"
cp    "$SRC/Kvantum/Vendetta/"*                   "$DST/Kvantum/Vendetta/"
printf '[General]\ntheme=Vendetta\n'            > "$HOME/.config/Kvantum/kvantum.kvconfig"
cp    "$SRC/fonts/truetype/chakra-petch/"*.ttf    "$HOME/.fonts/"
fc-cache -f "$HOME/.fonts" >/dev/null

if command -v plasma-apply-lookandfeel >/dev/null; then
	# one shot: LnF carries colour scheme, fonts, deco, Kvantum style, panel layout
	plasma-apply-lookandfeel -a org.vendetta.desktop
	plasma-apply-colorscheme Vendetta
	plasma-apply-desktoptheme Vendetta
	plasma-apply-wallpaperimage "$DST/wallpapers/Vendetta/contents/images/1920x1080.png" || true
	kwriteconfig6 --file kdeglobals --group General --key widgetStyle kvantum
	kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Vendetta.profile
	qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
	echo "Applied. Log out/in for fonts + SDDM + panel layout."
else
	echo "Copied. Not a running Plasma session — pick 'Vendetta' in System Settings."
fi
