# Vendetta Council OS

A themed Linux remaster in four editions that share one look: near-black, flat,
zero-radius, cyan accent. Not a from-scratch distro; each edition is the upstream
distribution plus Vendetta branding, a curated toolset and a Calamares installer
that lets you pick your desktop and login manager.

| Edition | Base | Build tool | Output |
|---|---|---|---|
| Debian (flagship) | Debian 13 "trixie" | `live-build` | `live-image-amd64.hybrid.iso` |
| Arch | Arch Linux (rolling) | `archiso` (releng) | `arch/out/vendetta-arch-amd64.iso` |
| Fedora | Fedora 43 KDE | `livecd-creator` | `fedora/out/vendetta-fedora-amd64.iso` |
| NixOS | NixOS 25.05 | flake | `vendetta-nixos-amd64.iso` |

## What you get

**Live session:** KDE Plasma 6 on Wayland with the Vendetta theme, and an
"Install Vendetta" launcher on the desktop.

**Installer choices** (Calamares):

| Desktop | Session type | Launcher | Terminal |
|---|---|---|---|
| KDE Plasma 6 (default) | Wayland | Plasma launcher | Konsole |
| GNOME | Wayland | Activities | GNOME Terminal |
| Xfce | X11 | Whisker menu | Xfce Terminal |
| Cinnamon | X11 | Cinnamon menu | GNOME Terminal |
| i3 | X11 | rofi | kitty |
| Sway | Wayland | wofi | kitty |
| Hyprland | Wayland | wofi | kitty |

| Login manager | Notes |
|---|---|
| SDDM | Vendetta theme, the default |
| LightDM | slick-greeter, Vendetta background |
| greetd | tuigreet, cyan text-mode login |

Only the chosen desktop is kept: picking anything other than KDE downloads it
during installation (internet required) and removes KDE. If the download fails,
KDE is left in place so the system still boots to a desktop.

On Debian, Arch and Fedora all three login managers are installed, so you can
switch later:

```sh
sudo vendetta-dm sddm      # or lightdm, greetd
```

**Preinstalled software** (the exact set varies slightly by edition)

- Desktop: Plasma 6, Dolphin, Konsole, Kate, Ark, Gwenview, Okular, Spectacle, Discover
- Browser: Firefox
- Terminal and shell: kitty, zsh, tmux
- CLI tools: git, curl, wget, ripgrep, fd, bat, fzf, jq, btop, htop, micro, tree, ncdu, fastfetch, nmap
- Runtimes: Python 3 (venv, pip), Node.js and npm
- Audio and network: PipeWire, WirePlumber, NetworkManager
- Debian only: `nala` (parallel apt front end) and Flatpak

On Debian the extras come from one metapackage. `vendetta-tools` lists them and
`sudo apt remove vendetta-desktop && sudo apt autoremove` drops them.

**Spydir toolkit** (installed under `/opt/spydir`, wrappers in `/usr/local/bin`)

- Command line: `spy-crack`, `spy-trail`, `spy-vector`, `spy-wraith`, `spy-xray`, `spy-webster`
- Web apps with menu entries: SPY-RECON-MAPPER, SPY-OSINT-SUITE, SPY-PRIVACY-PULSE,
  SPY-KERNEL-TRIAGE, SPY-GEOINT, SPY-THREAT-HUNT
- Links to the Spydir OpSec and OSINT courses

On Fedora the toolkit is fetched on first boot rather than baked into the image,
so it needs a network connection then.

**Theme**

- Plasma colour scheme, desktop theme, look-and-feel package and panel layout
- Kvantum Qt style, GTK 3/4 settings, Konsole, kitty and Xfce Terminal palettes
- SDDM theme, Plymouth boot splash, GRUB theme, wallpapers, fastfetch logo
- Fonts: Chakra Petch (bundled) and JetBrains Mono

Palette and per-component notes are in [`theme/README.md`](theme/README.md).

## Keybindings

`Mod` is the Super (Windows) key. Workspaces 1 to 5 are bound.

### i3 and Sway

| Keys | Action |
|---|---|
| `Mod+Return` | Terminal (kitty) |
| `Mod+d` | App launcher (rofi on i3, wofi on Sway) |
| `Mod+Shift+q` | Close window |
| `Mod+h` `j` `k` `l` | Focus left, down, up, right |
| `Mod+Shift+h` `j` `k` `l` | Move window left, down, up, right |
| `Mod+1` … `Mod+5` | Switch to workspace |
| `Mod+Shift+1` … `Mod+Shift+5` | Move window to workspace |
| `Mod+f` | Fullscreen |
| `Mod+Shift+Space` | Toggle floating |
| `Mod+v` / `Mod+b` | Split vertically / horizontally |
| `Mod+s` / `Mod+w` / `Mod+e` | Stacking / tabbed / toggle split layout |
| `Mod+Shift+c` | Reload config |
| `Mod+Shift+r` | Restart i3 in place (i3 only) |
| `Mod+Shift+e` | Log out (i3 asks for confirmation) |

Bar: i3status on i3, waybar on Sway. Notifications: dunst on i3, mako on Sway.

### Hyprland

| Keys | Action |
|---|---|
| `Mod+Return` | Terminal (kitty) |
| `Mod+D` | App launcher (wofi) |
| `Mod+Q` | Close window |
| `Mod+Arrow keys` | Move focus |
| `Mod+1` … `Mod+5` | Switch to workspace |
| `Mod+Shift+1` … `Mod+Shift+5` | Move window to workspace |
| `Mod+F` | Fullscreen |
| `Mod+V` | Toggle floating |
| `Mod+J` | Toggle split direction |
| `Mod+M` | Exit Hyprland |

Bar: waybar. Notifications: mako. Wallpaper: swww.

The configs live in `~/.config/{i3,sway,hypr,waybar,rofi,wofi,mako}` and are
copied from `/etc/skel` for every new user.

## Build

Each edition builds in a throwaway container. You need Docker (privileged) and
roughly 15 GB free per edition.

```sh
./build-docker.sh                  # Debian
./arch/build-arch-docker.sh        # Arch
./fedora/build-fedora-docker.sh    # Fedora
nix build path:./nixos#iso         # NixOS (or run it inside the nixos/nix image)
```

On a Debian host you can build the flagship natively:

```sh
sudo apt install live-build dpkg-dev debhelper
sudo ./build.sh
```

Try an image in QEMU:

```sh
qemu-img create -f qcow2 disk.qcow2 30G
qemu-system-x86_64 -enable-kvm -cpu host -m 6G -smp 4 \
  -cdrom live-image-amd64.hybrid.iso -boot d \
  -drive file=disk.qcow2,if=virtio -vga virtio -display gtk
```

Hyprland and Sway need 3D acceleration in a VM: use
`-device virtio-vga-gl -display gtk,gl=on` instead of `-vga virtio`.

Live session login on Debian and Arch: user `vendetta`, password `vendetta`.

## Repository layout

```
auto/ build.sh build-docker.sh   Debian live-build entry points
config/                          Debian live-build tree
  includes.chroot/               files copied onto the image; the shared theme,
                                 /etc/skel configs and scripts live here
  package-lists/                 Debian package selection
  hooks/normal/                  build-time hooks (theme defaults, toolkit)
  bootloaders/                   live ISO boot menu
packages/vendetta-desktop/       Debian metapackage for the default toolset
brand/                           logo and wallpaper generator
theme/                           palette notes, installer for a non-Vendetta KDE system
arch/                            Arch edition (see arch/README.md)
fedora/                          Fedora edition (see fedora/README.md)
nixos/                           NixOS edition: ISO flake, installer config,
                                 and the module written to the installed system
```

Arch and Fedora pull the shared theme and skel files from
`config/includes.chroot` at build time (`arch/copy-shared-assets.sh`), so the
looks are defined once.

How the editions install:

- **Debian, Arch, Fedora** clone the live system to disk, then add the chosen
  desktop and remove KDE.
- **NixOS** generates `/etc/nixos/configuration.nix` plus `/etc/nixos/vendetta.nix`
  from your choices and builds the system from them, so it stays reproducible
  with `nixos-rebuild`.

## Known limitations

- Non-KDE desktops need internet during installation.
- Fedora does not package Hyprland; that choice enables the third-party COPR
  `sdegler/hyprland`.
- The Fedora boot menu entry is still labelled "Fedora Linux".
- The installed Arch system keeps stock `pacman.conf`; `tuigreet` and
  `lightdm-slick-greeter` came from chaotic-aur at build time and will not update
  unless you add that repository.
- KWin uses the Breeze window decoration recoloured by the scheme; the custom
  Aurorae decoration is unfinished.
- No package repository of our own: updates come from the upstream distribution.

## Licences

Bundled Chakra Petch is under the SIL Open Font License (`OFL.txt` beside the
font). The NixOS installer module is derived from `calamares-nixos-extensions`
(GPL-3.0-or-later). Everything else follows the licence of its upstream project.
