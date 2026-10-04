{ config, pkgs, lib, ... }:

let
  chakra-petch = pkgs.stdenvNoCC.mkDerivation {
    name = "chakra-petch";
    src = ./assets/chakra-petch;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype/chakra-petch
      cp $src/*.ttf $out/share/fonts/truetype/chakra-petch/
    '';
  };
  vendetta-colors = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-color-scheme";
    src = ./assets/Vendetta.colors;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/color-schemes
      cp $src $out/share/color-schemes/Vendetta.colors
    '';
  };
  vendetta-wallpaper = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-wallpaper";
    src = ./assets/wallpaper-Vendetta;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/wallpapers
      cp -r $src $out/share/wallpapers/Vendetta
    '';
  };
  wallpaperImg = "${vendetta-wallpaper}/share/wallpapers/Vendetta/contents/images/1920x1080.png";

  vendetta-plymouth = pkgs.stdenvNoCC.mkDerivation {
    name = "vendetta-plymouth-theme";
    src = ./assets/plymouth;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/plymouth/themes/vendetta
      cp -r $src/* $out/share/plymouth/themes/vendetta/
    '';
  };
in
{
  # --- identity / branding ---
  system.nixos.distroName = "Vendetta Council OS";
  system.nixos.distroId   = "vendetta";
  networking.hostName     = "vendetta";
  isoImage.isoName        = lib.mkForce "vendetta-nixos-amd64.iso";
  # Rice the live ISO's boot menu (the installer's bootloader splash) — syslinux
  # on BIOS, GRUB on UEFI. Separate from the installed-system GRUB rice.
  # BIOS/isolinux menu runs at 800x600 and scales the background to fit, so a
  # 16:9 image gets squished — use a letterboxed 800x600 (4:3) splash instead.
  isoImage.splashImage    = lib.mkForce ./assets/boot-splash-bios.png;
  isoImage.efiSplashImage = lib.mkForce ./assets/grub-bg.png;
  # UEFI/GRUB: a theme always wins over efiSplashImage (and with no theme the
  # stock menu colours are unreadable on a dark splash), so ship the same theme
  # the Debian live ISO uses, over the Vendetta background.
  isoImage.grubTheme = pkgs.runCommand "vendetta-grub-theme" { } ''
    mkdir -p $out
    cp ${./assets/grub-theme/theme.txt} $out/theme.txt
    cp ${./assets/grub-bg.png} $out/background.png
  '';

  # Vendetta plymouth splash on the LIVE ISO too (was default KDE).
  boot.plymouth = {
    enable = true;
    theme = lib.mkForce "vendetta";
    themePackages = [ vendetta-plymouth ];
  };

  environment.systemPackages = with pkgs; [
    git python3 firefox
    btop ripgrep fd bat fzf kitty micro zsh tmux fastfetch neofetch nmap
    vendetta-colors vendetta-wallpaper
  ];

  fonts.packages = [ chakra-petch pkgs.jetbrains-mono ];

  # --- full Plasma rice for the live `nixos` user via plasma-manager ---
  home-manager.useGlobalPkgs = true;
  home-manager.users.nixos = { ... }: {
    home.stateVersion = "25.05";
    programs.plasma = {
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
  };

  # --- rebrand Calamares: the NixOS ISO's installer branding comes from
  #     calamares-nixos-extensions (shortProductName=NixOS, snowflake logo, blue
  #     sidebar). Override it to Vendetta so the installer isn't stock NixOS. ---
  nixpkgs.overlays = [
    (final: prev: {
      calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          bdir=$out/share/calamares/branding/nixos
          sed -i \
            -e 's|^\(\s*shortProductName:\).*|\1 Vendetta|' \
            -e 's|^\(\s*shortVersionedName:\).*|\1 Vendetta Council OS 1.0|' \
            -e 's|^\(\s*versionedName:\).*|\1 Vendetta Council OS 1.0|' \
            -e 's|^\(\s*bootloaderEntryName:\).*|\1 Vendetta|' \
            -e 's|^\(\s*productName:\).*|\1 Vendetta Council OS|' \
            -e 's|^\(\s*productLogo:\).*|\1 "vendetta-logo.png"|' \
            -e 's|^\(\s*productIcon:\).*|\1 "vendetta-logo.png"|' \
            -e 's|^\(\s*productWelcome:\).*|\1 "vendetta-logo.png"|' \
            -e 's|^\(\s*SidebarBackground:\).*|\1 "#04090A"|' \
            -e 's|^\(\s*SidebarText:\).*|\1 "#CFE6E6"|' \
            -e 's|^\(\s*SidebarTextCurrent:\).*|\1 "#04090A"|' \
            -e 's|^\(\s*SidebarBackgroundCurrent:\).*|\1 "#37E6D8"|' \
            "$bdir/branding.desc"
          cp -f ${./assets/sigil.png} "$bdir/vendetta-logo.png"

          # align the installer flow to the Debian build: trimmed desktop list
          # (plasma6/gnome/xfce/cinnamon + none), btrfs offered alongside ext4,
          # and a simpler password step (reuse admin pw, no forced-strong default).
          mdir=$out/share/calamares/modules
          cp -f ${./calamares-conf/packagechooser.conf} "$mdir/packagechooser.conf"
          cp -f ${./calamares-conf/partition.conf}      "$mdir/partition.conf"
          cp -f ${./calamares-conf/users.conf}          "$mdir/users.conf"
          # drop the NixOS-only "Unfree Software" step + add a login-manager
          # chooser step (settings.conf) and its config.
          cp -f ${./calamares-conf/settings.conf}             "$out/share/calamares/settings.conf"
          cp -f ${./calamares-conf/packagechooser-login.conf} "$mdir/packagechooser-login.conf"
          # patched nixos config-generator: writes the chosen DM (sddm/lightdm/
          # greetd+tuigreet) from packagechooser_login instead of hardcoding it,
          # AND lays the Vendetta module + assets into the target's /etc/nixos so
          # the INSTALLED system (not just the live ISO) gets the Vendetta tools,
          # fonts, branding, Plasma rice and spydir toolkit.
          ndir=$out/lib/calamares/modules/nixos
          cp -f ${./calamares-conf/nixos-main.py}       "$ndir/main.py"
          cp -f ${./calamares-conf/vendetta-system.nix} "$ndir/vendetta-system.nix"
          rm -rf "$ndir/vendetta-assets"
          cp -r ${./assets} "$ndir/vendetta-assets"
          chmod -R u+w "$ndir/vendetta-assets"
        '';
      });
    })
  ];

  # the live ISO's nixos-install needs flakes enabled to build the target config
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;
}
