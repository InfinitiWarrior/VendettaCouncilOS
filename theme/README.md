# Vendetta — KDE Plasma 6 theme

Near-black, flat, zero-radius. Cyan is an accent only — active app, cursor,
focus ring, selection, "secure" indicator. No glows, gradients, or rounded
corners.

## Palette

| Role | Hex | RGB |
|---|---|---|
| Window / panel base | `#04090A` | 4,9,10 |
| Surface | `#061012` | 6,16,18 |
| Surface raised / hover | `#0A181B` | 10,24,27 |
| Border / hairline | `#1B2A2C` | 27,42,44 |
| Text primary | `#CFE6E6` | 207,230,230 |
| Text secondary | `#A9C4C6` | 169,196,198 |
| Text disabled | `#5A6E70` | 90,110,112 |
| Accent (cyan) | `#37E6D8` | 55,230,216 |
| Accent hover | `#7CFFF3` | 124,255,243 |
| Negative | `#D63C48` | 214,60,72 |
| Selection bg (accent @12% on surface) | `#0C2A2A` | 12,42,42 |

Fonts: **Chakra Petch** (UI, bundled), **JetBrains Mono** (mono, from `fonts-jetbrains-mono`).

## Implemented

| # | Item | File |
|---|---|---|
| 1 | Color scheme | `config/includes.chroot/usr/share/color-schemes/Vendetta.colors` |
| 2 | Plasma desktop theme | `…/plasma/desktoptheme/Vendetta/` — colors + flat panel bg, inherits Breeze shapes |
| 3 | Window decoration | **Breeze, flat (no gradient), borderless**, recoloured near-black by the scheme. The Aurorae `…/aurorae/themes/Vendetta/` SVG is not KWin-6-conformant yet (falls back to Breeze) — WIP, needs a real KDE box to finish. |
| 6 | Konsole | `…/konsole/Vendetta.{profile,colorscheme}` |
| 7 | SDDM login | `…/sddm/themes/vendetta/` — sigil @30%, one field, cyan underline |
| 8 | Wallpaper | `…/wallpapers/Vendetta/` — sigil on near-black radial |
| 5 | GTK bridge | `etc/xdg/gtk-{3,4}.0/settings.ini` + `kde-config-gtk-style` keeps it in sync |
| 4 | Kvantum (Qt widget style) | `…/Kvantum/Vendetta/` — flat, near-0-radius, no shadows; SVG forked from KvFlat, palette + geometry ours. `widgetStyle=kvantum` |
| 9 | Panel + dock layout | LnF `…/look-and-feel/org.vendetta.desktop/contents/layouts/` — 40px top panel (launcher/spacer/tray/clock), 64px floating left icon-dock |
| 10 | Task active-indicator | `…/desktoptheme/Vendetta/widgets/tasks.svg` — 2px cyan bar on the focused task |
| — | Fonts | `…/fonts/truetype/chakra-petch/` (Chakra Petch not packaged in Debian) |

Defaults are applied system-wide by `config/hooks/normal/0120-vendetta.hook.chroot`
(writes `/etc/xdg/*` via `kwriteconfig6`) and by the `org.vendetta.desktop`
look-and-feel package (applied on first KDE login by
`/usr/lib/vendetta-apply-theme`, which also runs the panel layout script).

## Gotchas found the hard way

- **Plasma 6.3 (trixie) reads `[org.kde.kdecoration3]`** in kwinrc, not
  `[org.kde.kdecoration2]`. The hook + LnF defaults write both.
- `ColorScheme=Name` alone in kdeglobals is not enough — apps fall back to
  built-in Breeze colours unless the actual `[Colors:*]` / `[ColorEffects:*]` /
  `[WM]` groups are in a kdeglobals they read. The hook merges the whole
  `Vendetta.colors` into `/etc/xdg/kdeglobals` **and** `/etc/skel/.config/`.
- LnF `contents/defaults` is never auto-applied on a fresh profile — only the
  layout script runs. Wallpaper image is set in the layout script; everything
  else rides on /etc/skel + the first-login `plasma-apply-lookandfeel`.

## Not done yet

- **Aurorae "Vendetta" decoration** — the hand-rolled SVGs don't satisfy KWin 6's
  Aurorae loader (dup element ids, `-inactive` infix vs suffix, no button
  backgrounds, 0 padding). KWin silently uses Breeze instead. Rebuild the theme
  from a working template (e.g. a Plasma 6 Aurorae theme) on a real KDE box,
  then flip `library`→`org.kde.kwin.aurorae` / `theme`→`__aurorae__svg__Vendetta`
  in the hook + LnF defaults.
- **SDDM greeter + lock screen** — the in-session lock is kscreenlocker using
  Breeze's look-and-feel lockscreen (we don't ship one in `org.vendetta.desktop`);
  the `usr/share/sddm/themes/vendetta/` QML theme still needs a real greeter test.
- **Custom Plasma theme SVGs** beyond the panel background + task indicator
  (button / slider / checkbox shapes still come from Breeze — the color scheme
  recolours them, Kvantum handles the Qt-app side).
- **Panel translucency/blur.** The panel is opaque
  near-black (cleaner, matches "no glows"). Flip in `panel-background.svg` if
  wanted.

## Trying it on a running system

```sh
./theme/install.sh     # copies into ~/.local/share and applies via plasma-apply-*
```
