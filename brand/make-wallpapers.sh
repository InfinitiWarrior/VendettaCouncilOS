#!/bin/sh
# Regenerate the shipped wallpapers from brand/sigil.png. Needs ImageMagick.
set -e
cd "$(dirname "$0")/.."
OUT=config/includes.chroot/usr/share/wallpapers/Vendetta/contents/images
mkdir -p "$OUT"
gen() { # w h sigilpx outfile
	magick -size "${1}x${2}" radial-gradient:'#0B2124'-'#04090A' \
		\( brand/sigil.png -resize "${3}x${3}" -alpha set -channel A -evaluate multiply 0.40 +channel \) \
		-gravity center -composite -depth 8 "$4"
}
gen 3840 2160 1000 "$OUT/3840x2160.png"
gen 2560 1440 670  "$OUT/2560x1440.png"
gen 1920 1080 500  "$OUT/1920x1080.png"
magick "$OUT/1920x1080.png" -resize 1000x "$OUT/../screenshot.png"
echo "wallpapers regenerated"
