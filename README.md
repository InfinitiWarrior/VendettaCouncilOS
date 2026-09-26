# Vendetta Council OS

A Debian remaster — **not** a from-scratch distro. Base is Debian 13 (trixie),
desktop is KDE Plasma 6 on Wayland, package manager is apt (plus `nala`). Built
with `live-build`. Near-black flat theme, cyan accent.

## Why these choices

| Decision | Reason |
|---|---|
| Debian trixie base | apt comes free; `live-build` is first-class; ships Plasma 6 and native parallel apt. |
| KDE Plasma 6 | Most customizable desktop that needs no forking. Swap DE = edit `config/package-lists/desktop.list.chroot`. |
| `nala` by default | Parallel + segmented downloads, fastest-mirror pick. |
| Branding via `includes.chroot` + one hook | Fewer moving parts than a branding `.deb`. Tools go in a metapackage so they stay removable. |

## Build

Needs root and ~15 GB free.

**Non-Debian host (Arch, Fedora, macOS+Docker):**
```sh
./build-docker.sh        # builds in a throwaway debian:trixie container
```

**Debian host:**
```sh
sudo apt install live-build dpkg-dev debhelper
sudo ./build.sh
```

Output: `live-image-amd64.hybrid.iso`. Test: `qemu-system-x86_64 -enable-kvm -m 4G -cdrom live-image-amd64.hybrid.iso`.

## Layout

```
auto/config                  live-build knobs (distro, arch, DE session)
build.sh / build-docker.sh   metapackage + lb clean/config/build
brand/sigil.png              the logo — source of truth
brand/make-wallpapers.sh     regenerate wallpapers from the sigil
packages/vendetta-desktop/   the "nice tools" metapackage (edit debian/control)
theme/install.sh             apply the Plasma theme on a running non-Vendetta system
config/package-lists/
  desktop.list.chroot        Plasma 6 + theming bridges (kvantum, papirus, gtk)
  vendetta.list.chroot       pulls in the vendetta-desktop metapackage
config/hooks/normal/
  0120-vendetta.hook.chroot  fc-cache + plymouth + all Plasma defaults via kwriteconfig6
config/bootloaders/          live ISO boot menu (isolinux + grub) — Vendetta splash + cyan menu
config/includes.chroot/      copied onto the image as-is:
  usr/lib/os-release
  usr/share/color-schemes/Vendetta.colors
  usr/share/plasma/desktoptheme/Vendetta/
  usr/share/plasma/look-and-feel/org.vendetta.desktop/  colour+font+deco+kvantum+panel-layout defaults
  usr/share/aurorae/themes/Vendetta/          window decoration
  usr/share/Kvantum/Vendetta/                 Qt widget style (flat, 0-radius)
  usr/share/konsole/Vendetta.{profile,colorscheme}
  usr/share/sddm/themes/vendetta/             login screen
  usr/share/wallpapers/Vendetta/
  usr/share/fastfetch/logos/vendetta.txt      fastfetch sigil
  usr/share/fonts/truetype/chakra-petch/      bundled (not in Debian)
  usr/share/plymouth/themes/vendetta/         boot splash
  usr/lib/vendetta-apply-theme               first-login LnF apply (autostart)
  etc/calamares/branding/debian/              installer rebranded to Vendetta
  etc/sysctl.d/99-vendetta.conf              desktop responsiveness knobs
  etc/xdg/gtk-{3,4}.0/settings.ini            GTK bridge
  etc/skel/.config/{fastfetch,Kvantum}/
```

## Theme

See `theme/README.md` for the palette, what's implemented, and what's left.

## Known soft spots

- **First-login theme apply.** `org.vendetta.desktop` (a real Look-and-Feel
  package) carries the colour scheme, fonts, decoration, Kvantum style and the
  panel layout. Plasma does not auto-apply a LnF `defaults` file on a fresh
  profile, so `/usr/lib/vendetta-apply-theme` (autostart, marker-guarded) runs
  `plasma-apply-lookandfeel` once on first KDE login. The hook also writes the
  same keys to `/etc/xdg/*` as a fallback.
- **Widget SVGs** past the panel background + task indicator still come from
  Breeze (recoloured). Kvantum covers the Qt-app side.
- **Panel is opaque**, not the 82%+blur the brief mentions — deliberate, matches
  "no glows". One edit in `panel-background.svg` to change.
- **GRUB theme** for the *installed* system uses a generated background; the
  live ISO boot menu (isolinux + grub) is themed under `config/bootloaders/`.
- No custom apt repo.
