#!/bin/sh
# Vendetta Council OS (Arch) — apply KDE/Plasma branding as system-wide defaults.
# Ported from the Debian build's 0120 hook; runs inside the airootfs chroot via
# customize_airootfs.sh. Writes to /etc/xdg (the fallback layer Plasma honours on
# a fresh profile) and seeds the same values into /etc/skel.
set -e
fc-cache -f >/dev/null 2>&1 || true

KW=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
[ -n "$KW" ] || { echo "W: no kwriteconfig, skipping KDE defaults"; exit 0; }

install -d /etc/xdg
FONT="Chakra Petch,10,-1,5,50,0,0,0,0,0,Regular"
MONO="JetBrains Mono,11,-1,5,50,0,0,0,0,0,Regular"

"$KW" --file /etc/xdg/kdeglobals --group General --key ColorScheme Vendetta
"$KW" --file /etc/xdg/kdeglobals --group General --key AccentColor "55,230,216"
"$KW" --file /etc/xdg/kdeglobals --group General --key widgetStyle kvantum

CS=/usr/share/color-schemes/Vendetta.colors
if [ -f "$CS" ]; then
	awk '
		/^\[/   { keep = ($0 != "[General]" && $0 != "[KDE]") }
		keep    { print }
	' "$CS" >> /etc/xdg/kdeglobals
fi
"$KW" --file /etc/xdg/kdeglobals --group KDE --key contrast 4
"$KW" --file /etc/xdg/kdeglobals --group General --key font "$FONT"
"$KW" --file /etc/xdg/kdeglobals --group General --key fixed "$MONO"
"$KW" --file /etc/xdg/kdeglobals --group General --key menuFont "$FONT"
"$KW" --file /etc/xdg/kdeglobals --group General --key toolBarFont "$FONT"
"$KW" --file /etc/xdg/kdeglobals --group General --key smallestReadableFont "Chakra Petch,8,-1,5,50,0,0,0,0,0,Regular"
"$KW" --file /etc/xdg/kdeglobals --group WM --key activeFont "$FONT"
"$KW" --file /etc/xdg/kdeglobals --group Icons --key Theme Papirus-Dark
"$KW" --file /etc/xdg/kdeglobals --group KDE --key widgetStyle kvantum

install -d /etc/skel/.config/Kvantum
printf '[General]\ntheme=Vendetta\n' > /etc/skel/.config/Kvantum/kvantum.kvconfig
"$KW" --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage org.vendetta.desktop
"$KW" --file /etc/xdg/plasmarc --group Theme --key name Vendetta

for g in org.kde.kdecoration2 org.kde.kdecoration3; do
	"$KW" --file /etc/xdg/kwinrc --group "$g" --key library org.kde.breeze
	"$KW" --file /etc/xdg/kwinrc --group "$g" --key theme Breeze
	"$KW" --file /etc/xdg/kwinrc --group "$g" --key ButtonsOnLeft "M"
	"$KW" --file /etc/xdg/kwinrc --group "$g" --key ButtonsOnRight "IAX"
	"$KW" --file /etc/xdg/kwinrc --group "$g" --key BorderSize None
done
"$KW" --file /etc/xdg/breezerc --group Windeco --key DrawBackgroundGradient false
"$KW" --file /etc/xdg/breezerc --group Windeco --key DrawTitleBarSeparator false
"$KW" --file /etc/xdg/breezerc --group Windeco --key TitleAlignment AlignLeft
"$KW" --file /etc/xdg/breezerc --group Common --key OutlineCloseButton false

"$KW" --file /etc/xdg/konsolerc --group "Desktop Entry" --key DefaultProfile Vendetta.profile
"$KW" --file /etc/xdg/kscreenlockerrc --group Daemon --key Autolock false
"$KW" --file /etc/xdg/kscreenlockerrc --group Daemon --key LockOnResume false
"$KW" --file /etc/xdg/kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
"$KW" --file /etc/xdg/kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
	--key Image "file:///usr/share/wallpapers/Vendetta/"

# User avatar for the live `vendetta` user (installed accounts get it at runtime
# via vendetta-avatar.service, which keys on uid 1000).
install -d /var/lib/AccountsService/icons /var/lib/AccountsService/users
if [ -f /usr/share/vendetta/sigil.png ]; then
	install -m 0644 /usr/share/vendetta/sigil.png /var/lib/AccountsService/icons/vendetta
	cat > /var/lib/AccountsService/users/vendetta <<-EOF
	[User]
	Icon=/var/lib/AccountsService/icons/vendetta
	SystemAccount=false
	EOF
fi

kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
"$KW" --file /etc/xdg/kdeglobals --group KDE --key GTKStyle Breeze

install -d /etc/skel/.config
for f in kdeglobals kwinrc breezerc kscreenlockerrc; do
	[ -f "/etc/xdg/$f" ] && cp "/etc/xdg/$f" "/etc/skel/.config/$f"
done
