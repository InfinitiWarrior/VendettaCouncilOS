%include fedora-live-kde.ks

part / --size 12288 --fstype ext4

repo --name=fedora  --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-43&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f43&arch=$basearch

%packages
calamares
greetd
tuigreet
lightdm
slick-greeter
git
python3
python3-pip
python3-pillow
nodejs
npm
plymouth
plymouth-plugin-label
papirus-icon-theme
jetbrains-mono-fonts
qt6ct
kvantum
grub2-tools
grub2-tools-extra
efibootmgr
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

%post --nochroot
cp -a /tmp/overlay/. "$INSTALL_ROOT/" || cp -a /tmp/overlay/. "$LIVE_ROOT/"
%end

%post
set +e
ln -sf /usr/lib/os-release /etc/os-release
rm -f /etc/system-release-cpe 2>/dev/null

sh /root/vendetta-hook.sh

systemctl enable vendetta-spydir-setup.service 2>/dev/null || true

plymouth-set-default-theme vendetta 2>/dev/null || true

install -d /etc/skel/Desktop
install -m 0755 /usr/share/applications/vendetta-install.desktop /etc/skel/Desktop/vendetta-install.desktop
rm -f /usr/share/applications/liveinst.desktop

systemctl enable vendetta-avatar.service 2>/dev/null || true
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

fc-cache -f >/dev/null 2>&1 || true
%end
