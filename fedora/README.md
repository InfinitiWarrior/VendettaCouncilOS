# Vendetta Council OS — Fedora edition

A `livecd-creator` build of Vendetta Council OS on top of Fedora's own KDE live
spin. Calamares installs by **cloning the live base rootfs** (`unpackfs` from
`/dev/mapper/live-base`), so the installed system is the live system — all
branding, theming, `/etc/skel` configs and the spydir toolkit carry over (same
clone model as the Debian and Arch builds; the opposite of NixOS).

## Build

```sh
./fedora/build-fedora-docker.sh      # needs docker (privileged) + ~15 GB free
```

Output: `fedora/out/vendetta-fedora-amd64.iso`.

## How it fits together

- **Base**: `fedora-live-kde.ks` from the `fedora-kickstarts` repo (f41 branch,
  cloned at build time) — reused for its livesys autologin / live-user machinery.
  Our `vendetta.ks` `%include`s it, adds repos + our packages, swaps Anaconda's
  launcher for Calamares, and injects the overlay.
- **Overlay**: `fedora/overlay-extra/` (Fedora Calamares config, os-release,
  greeter configs, scripts, installer launcher) plus the shared branding/theme/
  skel/toolkit assets pulled from `../config/includes.chroot` by the Arch asset
  copier. `vendetta-hook.sh` + `spydir-setup.sh` are reused from `../arch/`.
- **Everything from base repos**: calamares, greetd, tuigreet, slick-greeter are
  all in Fedora's repos — no third-party repo needed.
- **Install flow**: desktop chooser (KDE default + i3/Hyprland/Sway/XFCE/GNOME/
  Cinnamon via dnf, lean — KDE stripped) and login chooser (sddm/lightdm/greetd,
  all preinstalled, switchable with `sudo vendetta-dm <name>`). Calamares, the
  live-only launcher/polkit rule, and livesys are removed from the target on
  install; an SELinux relabel is scheduled (`/.autorelabel`).

## Known ceilings (test + iterate)

- `livecd-creator` in a container can stumble on SELinux relabel / loop devices;
  diagnose from the build log if it fails.
- `hyprland`/`swww` may not be in Fedora's base repos — that desktop pick would
  fall back to keeping KDE (graceful). Add a COPR in `vendetta-desktop-setup` if
  needed.
- Non-KDE desktops install at install-time and need internet (parity with the
  other builds).
- The spydir toolkit is built on **first boot** (systemd `vendetta-spydir-setup.service`),
  not baked into the image — Fedora's livecd build chroot has no usable DNS for the
  git clones. So the live session and the installed system each fetch it once on
  their first boot (needs network then). Debian/Arch bake it in at build time.
