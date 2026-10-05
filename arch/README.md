# Vendetta Council OS — Arch edition

An `archiso` build of Vendetta Council OS. Calamares installs by **cloning the
live squashfs** (`unpackfs`), so the installed system is the live system — all
branding, theming, `/etc/skel` configs and the spydir toolkit carry over
automatically (same model as the Debian flagship, unlike NixOS which regenerates
its config).

## Build

```sh
./arch/build-arch-docker.sh      # needs docker (privileged) + ~15 GB free
```

Output: `arch/out/vendetta-arch-amd64.iso`.

## How it fits together

- **Base**: archiso `releng` profile, overlaid with `airootfs/`, `packages.x86_64.extra`,
  `pacman-extra.conf`, and the live setup appended to `customize_airootfs.sh`.
- **Shared assets**: `copy-shared-assets.sh` pulls the distro-agnostic branding/
  theme/skel/toolkit files from `../config/includes.chroot`, so both ISOs ship
  identical looks. Nothing is duplicated in git.
- **chaotic-aur**: supplies prebuilt `calamares`, `greetd-tuigreet`,
  `lightdm-slick-greeter` (`SigLevel=Never` only during the build).
- **Live session**: autologin as `vendetta` into a Plasma Wayland session, installer launcher on the desktop.
- **Install flow**: Calamares desktop chooser (KDE default + i3/Hyprland/Sway/
  XFCE/GNOME/Cinnamon, lean — only the pick is installed, KDE stripped) and a
  login chooser (sddm/lightdm/greetd, all preinstalled, switchable later with
  `sudo vendetta-dm <name>`). Calamares + the live-only user/autologin/polkit are
  removed from the target on install.

## Known limitations

- The non-KDE desktops install at install-time and need internet (parity with Debian).
- Installed system keeps releng's `pacman.conf` (no chaotic-aur); add it back if
  you want updates for tuigreet/slick-greeter.
