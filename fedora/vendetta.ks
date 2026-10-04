# Vendetta Council OS — Fedora live ISO (livecd-creator).
# Builds on Fedora's own KDE live spin (reusing its livesys autologin/live-user
# machinery), swaps Anaconda for Calamares, and injects the Vendetta overlay.
# The installer clones the live base rootfs (Calamares unpackfs /dev/mapper/
# live-base), so the installed system IS the live system.

# Built from inside a clone of fedora-kickstarts (f43), so this relative include
# and its own %include chain (fedora-live-base.ks, fedora-kde-common.ks) resolve.
%include fedora-live-kde.ks

# The spin's default root image leaves under 1 GB free once our packages are in,
# and the first-boot toolkit install then fills the live system completely.
part / --size 12288 --fstype ext4

# The upstream kickstarts carry no repo lines (koji injects them at compose
# time), so livecd-creator needs ours.
repo --name=fedora  --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-43&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f43&arch=$basearch

%packages
# --- installer (clone-based) ---
calamares
# --- login managers (all three; sddm stays the KDE-spin default) ---
greetd
tuigreet
lightdm
slick-greeter
# --- spydir toolkit build/runtime ---
git
python3
python3-pip
python3-pillow
nodejs
npm
# --- theming ---
plymouth
plymouth-plugin-label
papirus-icon-theme
jetbrains-mono-fonts
qt6ct
kvantum
# --- bootloader tooling for the installed system (Calamares) ---
grub2-tools
grub2-tools-extra
efibootmgr
# --- CLI tools (parity with the other builds) ---
fastfetch
btop
ripgrep
fd-find
bat
fzf
micro
tmux
zsh
nmap
kitty
%end

# Lay our overlay into the image (runs outside the chroot, after packages are
# installed, so overwriting package-owned files like os-release is fine).
%post --nochroot
cp -a /tmp/overlay/. "$INSTALL_ROOT/" || cp -a /tmp/overlay/. "$LIVE_ROOT/"
%end

%post
set +e
# OS identity.
ln -sf /usr/lib/os-release /etc/os-release
rm -f /etc/system-release-cpe 2>/dev/null

# KDE/Plasma branding -> /etc/xdg + /etc/skel.
sh /root/vendetta-hook.sh

# spydirbyte toolkit: deferred to first boot (needs real networking/DNS, which
# the livecd build chroot lacks). The oneshot service builds /opt/spydir once.
systemctl enable vendetta-spydir-setup.service 2>/dev/null || true

# Plymouth boot splash.
plymouth-set-default-theme vendetta 2>/dev/null || true

# Installer on the live desktop: liveuser is created from /etc/skel at boot, so
# drop the launcher there (executable, so Plasma trusts it). Remove Anaconda's.
install -d /etc/skel/Desktop
install -m 0755 /usr/share/applications/vendetta-install.desktop /etc/skel/Desktop/vendetta-install.desktop
rm -f /usr/share/applications/liveinst.desktop

# Keep sddm as the default login manager; seed the avatar at boot.
systemctl enable vendetta-avatar.service 2>/dev/null || true
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

fc-cache -f >/dev/null 2>&1 || true
%end
