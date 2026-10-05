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

  system.nixos.distroName = lib.mkForce "Vendetta Council OS";
  system.nixos.distroId   = lib.mkForce "vendetta";

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.motd = ''
      ██╗   ██╗ ██████╗
      ██║   ██║██╔════╝    Vendetta Council OS
      ██║   ██║██║          "Ideas are bulletproof."
      ╚██╗ ██╔╝██║
       ╚████╔╝ ╚██████╗
        ╚═══╝   ╚═════╝    extras: `vendetta-tools`
  '';

  environment.systemPackages = with pkgs; [
    git python3 nodejs xdg-utils
    btop ripgrep fd bat fzf kitty micro zsh tmux fastfetch neofetch nmap
    chakra-petch vendetta-colors vendetta-wallpaper vendetta-sddm
    vendetta-fastfetch vendetta-spydir
    papirus-icon-theme gnome-themes-extra
    xorg.xinit
  ]
  ++ lib.optional (gnomeEnabled || cinnamonEnabled) pkgs.gnome-terminal
  ++ lib.optionals i3Enabled (with pkgs; [ feh picom dunst rofi i3status networkmanagerapplet ])
  ++ lib.optionals (swayEnabled || hyprlandEnabled) (with pkgs; [ waybar mako wofi networkmanagerapplet ])
  ++ lib.optionals hyprlandEnabled (with pkgs; [ swww adwaita-icon-theme ]);
  fonts.packages = [ chakra-petch pkgs.jetbrains-mono ];
  environment.gnome.excludePackages = lib.mkIf gnomeEnabled [ pkgs.gnome-console ];

  environment.extraInit = ''
    case ":$PATH:" in
      *:/opt/spydir/bin:*) ;;
      *) PATH="$PATH:/opt/spydir/bin"; export PATH ;;
    esac
  '';

  services.xserver.enable = lib.mkIf (swayEnabled || hyprlandEnabled) true;
  services.xserver.displayManager.sessionCommands = lib.mkIf lightdmEnabled ''
    [ "$XDG_SESSION_TYPE" = wayland ] && sleep 3
  '';

  services.displayManager.sddm.package = lib.mkForce pkgs.kdePackages.sddm;
  services.displayManager.sddm.settings.Theme.Current = "vendetta";

  boot.loader.grub.splashImage = lib.mkIf config.boot.loader.grub.enable ./vendetta-assets/grub-bg.png;

  boot.plymouth = {
    enable = true;
    theme = "vendetta";
    themePackages = [ vendetta-plymouth ];
  };

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

  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "vendetta.bak";
  home-manager.users.${username} = { ... }: {
    imports = [ "${pmSrc}/modules" ];
    home.stateVersion = "@@nixosversion@@";

    home.file = lib.mkMerge [
      {
        ".config/fastfetch/config.jsonc".source = ./vendetta-assets/fastfetch/config.jsonc;
        ".config/kitty/kitty.conf".source = ./vendetta-assets/kitty.conf;
        ".config/gtk-3.0/settings.ini".source = ./vendetta-assets/gtk/settings.ini;
        ".config/gtk-4.0/settings.ini".source = ./vendetta-assets/gtk/settings.ini;
      }

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
        ".config/waybar/config-sway".source = "${wm}/waybar/config-sway";
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
      "org/cinnamon/theme" = { name = "Mint-Y-Dark-Aqua"; };
      "org/cinnamon/desktop/wm/preferences" = { theme = "Mint-Y-Dark-Aqua"; };
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
        "backdrop/screen0/monitor0/workspace0/last-image" = wallpaperImg;
        "backdrop/screen0/monitor0/workspace0/image-style" = 5;
        "backdrop/screen0/monitorVirtual-1/workspace0/last-image" = wallpaperImg;
        "backdrop/screen0/monitorVirtual-1/workspace0/image-style" = 5;
      };
      xfce4-terminal = {
        "font-use-system" = false;
        "font-name" = "JetBrains Mono 11";
        "color-use-theme" = false;
        "color-background" = "#04090A";
        "color-foreground" = "#DCECEB";
        "color-cursor-use-default" = false;
        "color-cursor" = "#37E6D8";
        "color-cursor-foreground" = "#04090A";
        "color-selection-use-default" = false;
        "color-selection-background" = "#37E6D8";
        "color-selection" = "#04090A";
        "color-palette" = "#04090A;#D63C48;#37E6D8;#A9C4C6;#36B2C6;#78C8DC;#37E6D8;#A9C4C6;#1B2A2C;#E65C66;#7CFFF3;#CFE6E6;#7CFFF3;#A0E8F0;#7CFFF3;#CFE6E6";
        "misc-cursor-shape" = "TERMINAL_CURSOR_SHAPE_IBEAM";
      };
    };
  };

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
