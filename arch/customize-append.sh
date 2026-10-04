
# ===== Vendetta Council OS — live-session + branding setup =====
# Appended to releng's customize_airootfs.sh; runs in the airootfs chroot.
set -e

# Lay down the files that are owned by the filesystem/calamares/greetd packages
# (staged under /root/overlay because pacstrap can't overwrite them at install
# time). Now that packages are in, overwriting is free. This brings in our
# os-release, /etc/calamares/*, the greetd/slick-greeter configs, issue + motd.
cp -a /root/overlay/. /

# OS identity: everything reads /etc/os-release -> point it at ours.
ln -sf /usr/lib/os-release /etc/os-release

# Apply KDE/Plasma branding to /etc/xdg + /etc/skel (before creating the live
# user, so its home inherits the themed skel).
sh /root/vendetta-hook.sh || echo "W: vendetta-hook failed"

# Preinstall the spydirbyte toolkit (needs network during build).
sh /root/spydir-setup.sh || echo "W: spydir-setup failed"

# Plymouth boot splash.
plymouth-set-default-theme vendetta 2>/dev/null || true

# Live user: vendetta / vendetta, passwordless sudo (rule shipped in /etc).
groupadd -r autologin 2>/dev/null || true
useradd -m -G wheel,autologin,video,audio,network,storage,power -s /bin/bash vendetta 2>/dev/null || true
echo 'vendetta:vendetta' | chpasswd
echo 'root:vendetta' | chpasswd

# Installer launcher on the live desktop (marked executable so Plasma trusts it).
install -d /home/vendetta/Desktop
install -m 0755 /usr/share/applications/vendetta-install.desktop /home/vendetta/Desktop/vendetta-install.desktop
chown -R vendetta:vendetta /home/vendetta

# Boot straight to the Vendetta SDDM greeter, autologin into the live Plasma
# (Wayland) session (autologin conf shipped in /etc/sddm.conf.d).
systemctl set-default graphical.target
systemctl enable sddm.service
# NetworkManager owns the network — turn off releng's systemd-networkd/iwd so the
# two stacks don't fight over the live link.
systemctl disable systemd-networkd.service systemd-networkd.socket iwd.service 2>/dev/null || true
systemctl enable NetworkManager.service
systemctl enable vendetta-avatar.service 2>/dev/null || true

# Nothing on this desktop waits for the network.
systemctl mask NetworkManager-wait-online.service 2>/dev/null || true

fc-cache -f >/dev/null 2>&1 || true
