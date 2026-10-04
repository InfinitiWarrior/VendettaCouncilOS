# Vendetta Council OS — installed-system module.
#
# NixOS's Calamares GENERATES a fresh configuration.nix (it does not clone the
# live system like the Debian/Arch/Fedora builds), so none of the live ISO's
# rice reaches the installed disk on its own. The installer (nixos-main.py)
# copies this file to the target's /etc/nixos/vendetta.nix, copies the assets to
# /etc/nixos/vendetta-assets/, and adds ./vendetta.nix to configuration.nix's
# imports — so the installed system gets the Vendetta tools, fonts, branding,
# Plasma rice, SDDM/fastfetch/GRUB theming, the user avatar, the WM rice and the
# spydir toolkit.
#
# @@username@@ / @@nixosversion@@ are substituted by nixos-main.py at install.
{ config, pkgs, lib, ... }:

let
  username = "@@username@@";
  plasmaEnabled   = config.services.desktopManager.plasma6.enable;
  i3Enabled       = config.services.xserver.windowManager.i3.enable or false;
  swayEnabled     = config.programs.sway.enable or false;
  hyprlandEnabled = config.programs.hyprland.enable or false;
  gnomeEnabled    = config.services.xserver.desktopManager.gnome.enable or false;
  cinnamonEnabled = config.services.xserver.desktopManager.cinnamon.enable or false;
  xfceEnabled     = config.services.xserver.desktopManager.xfce.enable or false;
  lightdmEnabled  = config.services.xserver.displayManager.lightdm.enable or false;

  # Pinned to the exact revisions the live ISO's flake.lock was tested with.
  hmSrc = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/44831a7eaba4360fb81f2acc5ea6de5fde90aaa3.tar.gz";
  };
  pmSrc = builtins.fetchTarball {
    url = "https://github.com/nix-community/plasma-manager/archive/a19a2a029fa180911bd89c554dca1616e10f4c1d.tar.gz";
  };

  chakra-petch = pkgs.stdenvNoCC.mkDerivation {
    name = "chakra-petch";
    src = ./vendetta-assets/chakra-petch;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype/chakra-petch
      cp $src/*.ttf $out/share/fonts/truetype/chakra-petch/
    '';
  };
  vendetta-colors = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-color-scheme";
    src = ./vendetta-assets/Vendetta.colors;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/color-schemes
      cp $src $out/share/color-schemes/Vendetta.colors
    '';
  };
  vendetta-wallpaper = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-wallpaper";
    src = ./vendetta-assets/wallpaper-Vendetta;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/wallpapers
      cp -r $src $out/share/wallpapers/Vendetta
    '';
  };
  wallpaperImg = "${vendetta-wallpaper}/share/wallpapers/Vendetta/contents/images/1920x1080.png";

  vendetta-sddm = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-sddm-theme";
    src = ./vendetta-assets/sddm-vendetta;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/vendetta
      cp -r $src/* $out/share/sddm/themes/vendetta/
    '';
  };

  vendetta-fastfetch = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-fastfetch-logo";
    src = ./vendetta-assets/fastfetch;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/fastfetch/logos
      cp $src/vendetta.txt $out/share/fastfetch/logos/vendetta.txt
    '';
  };

  # spydir web-app launchers: in the menu + PATH immediately (functional once the
  # first-boot service below has cloned the tools into /opt/spydir).
  vendetta-spydir = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-spydir-launchers";
    src = ./vendetta-assets/spydir;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin $out/share/applications
      cp $src/spydir-webapp $out/bin/spydir-webapp
      chmod +x $out/bin/spydir-webapp
      cp $src/applications/*.desktop $out/share/applications/
    '';
  };

  wm = ./vendetta-assets/wm;
  # The WM configs are shared with the FHS editions; point their wallpaper at
  # the store path (there is no /usr/share on NixOS).
  wmConf = f: builtins.replaceStrings
    [ "/usr/share/wallpapers/Vendetta/contents/images/1920x1080.png" ] [ wallpaperImg ]
    (builtins.readFile f);

  vendetta-plymouth = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-plymouth-theme";
    src = ./vendetta-assets/plymouth;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/plymouth/themes/vendetta
      cp -r $src/* $out/share/plymouth/themes/vendetta/
    '';
  };
in
{
  imports = [ "${hmSrc}/nixos" ];

  # --- identity / branding ---
  system.nixos.distroName = lib.mkForce "Vendetta Council OS";
  system.nixos.distroId   = lib.mkForce "vendetta";

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- console branding (motd) ---
  users.motd = ''
      ██╗   ██╗ ██████╗
      ██║   ██║██╔════╝    Vendetta Council OS
      ██║   ██║██║          "Ideas are bulletproof."
      ╚██╗ ██╔╝██║
       ╚████╔╝ ╚██████╗
        ╚═══╝   ╚═════╝    extras: `vendetta-tools`
  '';

  # --- CLI tools (the Vendetta "nice tools" set) + branding assets ---
  environment.systemPackages = with pkgs; [
    git python3 nodejs xdg-utils
    btop ripgrep fd bat fzf kitty micro zsh tmux fastfetch neofetch nmap
    chakra-petch vendetta-colors vendetta-wallpaper vendetta-sddm
    vendetta-fastfetch vendetta-spydir
    papirus-icon-theme gnome-themes-extra
    xorg.xinit  # startx — lets greetd/tuigreet launch X11 sessions
  ]
  # GNOME ships `kgx` (Console), not gnome-terminal — install gnome-terminal so
  # the Vendetta terminal profile (dconf) actually has an app to style.
  ++ lib.optional (gnomeEnabled || cinnamonEnabled) pkgs.gnome-terminal
  # The helpers the WM configs exec (bar, launcher, notifications, wallpaper).
  ++ lib.optionals i3Enabled (with pkgs; [ feh picom dunst rofi i3status networkmanagerapplet ])
  ++ lib.optionals (swayEnabled || hyprlandEnabled) (with pkgs; [ waybar mako wofi networkmanagerapplet ])
  ++ lib.optional hyprlandEnabled pkgs.swww;
  fonts.packages = [ chakra-petch pkgs.jetbrains-mono ];

  # spydir CLI wrappers (spy-crack, …) land in /opt/spydir/bin on first boot.
  environment.extraInit = ''
    case ":$PATH:" in
      *:/opt/spydir/bin:*) ;;
      *) PATH="$PATH:/opt/spydir/bin"; export PATH ;;
    esac
  '';

  # --- SDDM greeter theme. Two things were needed (both found from the greeter
  #     journal): (1) NixOS's default SDDM is Qt5.15, but our theme declares
  #     QtVersion=6 (Debian's SDDM is Qt6), so Qt5 SDDM REJECTS it and loads the
  #     built-in qrc:/theme default — force the Qt6 SDDM (kdePackages.sddm).
  #     (2) `.theme` does NOT write [Theme] Current on this release, so set it
  #     directly. The theme ships in vendetta-sddm (systemPackages); NixOS points
  #     ThemeDir at /run/current-system/sw/share/sddm/themes. ---
  services.displayManager.sddm.package = lib.mkForce pkgs.kdePackages.sddm;
  services.displayManager.sddm.settings.Theme.Current = "vendetta";

  # --- GRUB boot splash (only on BIOS/GRUB installs; systemd-boot has no splash) ---
  boot.loader.grub.splashImage = lib.mkIf config.boot.loader.grub.enable ./vendetta-assets/grub-bg.png;

  # --- Plymouth boot splash ---
  boot.plymouth = {
    enable = true;
    theme = "vendetta";
    themePackages = [ vendetta-plymouth ];
  };

  # --- LightDM greeter rice (dark GTK greeter + Vendetta wallpaper) ---
  services.xserver.displayManager.lightdm.background =
    lib.mkIf lightdmEnabled wallpaperImg;
  services.xserver.displayManager.lightdm.greeters.gtk = lib.mkIf lightdmEnabled {
    theme = { name = "Adwaita-dark"; package = pkgs.gnome-themes-extra; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    extraConfig = ''
      font-name = Chakra Petch 10
      background-color = #04090A
    '';
  };

  # --- user avatar: seed the Vendetta sigil via AccountsService (SDDM + Plasma
  #     both read it). Runs once before the greeter; never clobbers a user choice. ---
  systemd.services.vendetta-avatar = {
    description = "Vendetta Council OS — seed the sigil avatar for the primary user";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    unitConfig.ConditionPathExists = "!/var/lib/AccountsService/icons/${username}";
    serviceConfig.Type = "oneshot";
    script = ''
      install -d /var/lib/AccountsService/icons /var/lib/AccountsService/users
      install -m 0644 ${./vendetta-assets/sigil.png} /var/lib/AccountsService/icons/${username}
      cat > /var/lib/AccountsService/users/${username} <<EOF
      [User]
      Icon=/var/lib/AccountsService/icons/${username}
      SystemAccount=false
      EOF
    '';
  };

  # --- per-user rice via home-manager: fastfetch always; Plasma or the chosen
  #     WM get their Vendetta configs. ---
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "vendetta.bak";
  home-manager.users.${username} = { ... }: {
    imports = [ "${pmSrc}/modules" ];
    home.stateVersion = "@@nixosversion@@";

    home.file = lib.mkMerge [
      # fastfetch + kitty + GTK dark: themed for every desktop (GTK settings make
      # GTK apps dark even under WMs/Plasma, not just GNOME/Cinnamon/XFCE).
      {
        ".config/fastfetch/config.jsonc".source = ./vendetta-assets/fastfetch/config.jsonc;
        ".config/kitty/kitty.conf".source = ./vendetta-assets/kitty.conf;
        ".config/gtk-3.0/settings.ini".source = ./vendetta-assets/gtk/settings.ini;
        ".config/gtk-4.0/settings.ini".source = ./vendetta-assets/gtk/settings.ini;
      }

      # Konsole: Vendetta profile + colorscheme (Plasma's terminal).
      (lib.mkIf plasmaEnabled {
        ".local/share/konsole/Vendetta.profile".source = ./vendetta-assets/konsole/Vendetta.profile;
        ".local/share/konsole/Vendetta.colorscheme".source = ./vendetta-assets/konsole/Vendetta.colorscheme;
        ".config/konsolerc".text = ''
          [Desktop Entry]
          DefaultProfile=Vendetta.profile
        '';
      })

      (lib.mkIf i3Enabled {
        ".config/i3/config".text = wmConf "${wm}/i3/config";
        ".config/i3status/config".source = "${wm}/i3status/config";
        ".config/rofi/config.rasi".source = "${wm}/rofi/config.rasi";
        ".config/picom.conf".source = "${wm}/picom.conf";
      })
      (lib.mkIf swayEnabled {
        ".config/sway/config".text = wmConf "${wm}/sway/config";
        ".config/waybar/config".source = "${wm}/waybar/config";
        ".config/waybar/style.css".source = "${wm}/waybar/style.css";
        ".config/wofi/config".source = "${wm}/wofi/config";
        ".config/wofi/style.css".source = "${wm}/wofi/style.css";
        ".config/mako/config".source = "${wm}/mako/config";
      })
      (lib.mkIf hyprlandEnabled {
        ".config/hypr/hyprland.conf".text = wmConf "${wm}/hypr/hyprland.conf";
        ".config/waybar/config".source = "${wm}/waybar/config";
        ".config/waybar/style.css".source = "${wm}/waybar/style.css";
        ".config/wofi/config".source = "${wm}/wofi/config";
        ".config/wofi/style.css".source = "${wm}/wofi/style.css";
        ".config/mako/config".source = "${wm}/mako/config";
      })
    ];

    programs.plasma = lib.mkIf plasmaEnabled {
      enable = true;
      workspace = {
        lookAndFeel = "org.kde.breezedark.desktop";
        colorScheme = "Vendetta";
        wallpaper   = wallpaperImg;
      };
      fonts = {
        general    = { family = "Chakra Petch"; pointSize = 10; };
        fixedWidth = { family = "JetBrains Mono"; pointSize = 11; };
      };
    };

    # GNOME / Cinnamon rice: dark + teal accent + Vendetta wallpaper + terminal.
    dconf.settings = lib.mkIf (gnomeEnabled || cinnamonEnabled) {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
        accent-color = "teal";
        font-name = "Chakra Petch 10";
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file://${wallpaperImg}";
        picture-uri-dark = "file://${wallpaperImg}";
        picture-options = "zoom";
        primary-color = "#04090A";
      };
      "org/cinnamon/desktop/background" = {
        picture-uri = "file://${wallpaperImg}";
        picture-options = "zoom";
      };
      "org/cinnamon/desktop/interface" = {
        gtk-theme = "Mint-Y-Dark-Aqua";
        icon-theme = "Papirus-Dark";
        font-name = "Chakra Petch 10";
      };
      # The Cinnamon SHELL theme (panel/menu/applets) — unset = default light.
      # Mint-Y-Dark-Aqua is dark with a teal accent (ships with cinnamon).
      "org/cinnamon/theme" = { name = "Mint-Y-Dark-Aqua"; };
      # Window borders: Muffin reads org.cinnamon.desktop.wm.preferences (NixOS
      # defaults it to light Mint-Y), not the org.gnome key.
      "org/cinnamon/desktop/wm/preferences" = { theme = "Mint-Y-Dark-Aqua"; };
      # libadwaita/GTK4 apps follow the xapp portal colour scheme under Cinnamon.
      "org/x/apps/portal" = { color-scheme = "prefer-dark"; };
      "org/gnome/terminal/legacy/profiles:" = {
        default = "b1dcc9dd-5262-4d8d-a863-c897e6d979b9";
        list = [ "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" ];
      };
      "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        visible-name = "Vendetta";
        use-theme-colors = false;
        use-system-font = false;
        font = "JetBrains Mono 11";
        background-color = "#04090A";
        foreground-color = "#CFE6E6";
        bold-color-same-as-fg = true;
        cursor-colors-set = true;
        cursor-background-color = "#37E6D8";
        cursor-foreground-color = "#04090A";
        palette = [ "#04090A" "#D63C48" "#37E6D8" "#E6C437" "#3C7AD6" "#9B59B6" "#37E6D8" "#CFE6E6" "#5A6E70" "#D63C48" "#37E6D8" "#E6C437" "#3C7AD6" "#9B59B6" "#37E6D8" "#FFFFFF" ];
      };
    };

    # XFCE rice via xfconf (xfconf-query at activation — NOT read-only xml files,
    # which xfconfd can't manage). Dark theme + fonts + wallpaper + xfwm4 deco.
    xfconf.settings = lib.mkIf xfceEnabled {
      xsettings = {
        "Net/ThemeName" = "Adwaita-dark";
        "Net/IconThemeName" = "Papirus-Dark";
        "Gtk/FontName" = "Chakra Petch 10";
        "Gtk/MonospaceFontName" = "JetBrains Mono 11";
      };
      xfwm4 = {
        "general/theme" = "Default-xhdpi";
        "general/title_font" = "Chakra Petch Bold 9";
      };
      xfce4-desktop = {
        # cover the common monitor names (VMs = Virtual-1; many setups = monitor0)
        "backdrop/screen0/monitor0/workspace0/last-image" = wallpaperImg;
        "backdrop/screen0/monitor0/workspace0/image-style" = 5;
        "backdrop/screen0/monitorVirtual-1/workspace0/last-image" = wallpaperImg;
        "backdrop/screen0/monitorVirtual-1/workspace0/image-style" = 5;
      };
    };
  };

  # --- spydirbyte toolkit: built on first boot (clones 12 repos + a venv; needs
  #     network, so it can't be baked into the generated config). ---
  systemd.services.vendetta-spydir-setup = {
    description = "Vendetta Council OS — install the spydirbyte toolkit (first boot)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!/opt/spydir/.installed";
    path = with pkgs; [ git python3 nodejs gcc gnumake pkg-config ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -u
      BASE=/opt/spydir; VENV=$BASE/venv; GH=https://github.com/spydirbyte
      mkdir -p "$BASE/bin"
      ${pkgs.python3}/bin/python3 -m venv "$VENV"
      "$VENV/bin/pip" install --no-input --quiet --upgrade pip || true
      for name in spy-crack spy-geoint spy-kernel-triage spy-osint-suite spy-privacy-pulse \
                  spy-recon-mapper spy-threat-hunt spy-trail spy-vector spy-wraith spy-xray; do
        dir="$BASE/$name"
        git clone --depth 1 "$GH/$name.git" "$dir" || { echo "skip $name"; continue; }
        [ -f "$dir/requirements.txt" ] && "$VENV/bin/pip" install --no-input --quiet -r "$dir/requirements.txt" || true
        entry=""
        for e in cli.py app.py run.py; do [ -f "$dir/$e" ] && { entry=$e; break; }; done
        [ -n "$entry" ] || continue
        cat > "$BASE/bin/$name" <<EOF
#!/bin/sh
exec "$VENV/bin/python" "$dir/$entry" "\$@"
EOF
        chmod +x "$BASE/bin/$name"
      done
      if git clone --depth 1 "$GH/spy-webster.git" "$BASE/spy-webster"; then
        ( cd "$BASE/spy-webster" && npm ci --silent && npm run build --if-present ) && \
        cat > "$BASE/bin/spy-webster" <<EOF
#!/bin/sh
exec ${pkgs.nodejs}/bin/node "$BASE/spy-webster/dist/index.js" "\$@"
EOF
        [ -f "$BASE/bin/spy-webster" ] && chmod +x "$BASE/bin/spy-webster"
      fi
      touch "$BASE/.installed"
    '';
  };
}
