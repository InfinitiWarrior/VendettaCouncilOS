set -e

cp -a /root/overlay/. /

chmod 755 /usr/bin/vendetta-tools /usr/lib/vendetta-* /usr/local/sbin/vendetta-* \
	/usr/local/bin/vendetta-install /usr/local/bin/spydir-webapp

ln -sf /usr/lib/os-release /etc/os-release

sh /root/vendetta-hook.sh || echo "W: vendetta-hook failed"

sh /root/spydir-setup.sh || echo "W: spydir-setup failed"

plymouth-set-default-theme vendetta 2>/dev/null || true

cat >> /etc/skel/.bashrc <<'PROMPT'
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
PROMPT

groupadd -r autologin 2>/dev/null || true
useradd -m -G wheel,autologin,video,audio,network,storage,power -s /bin/bash vendetta 2>/dev/null || true
echo 'vendetta:vendetta' | chpasswd
echo 'root:vendetta' | chpasswd

install -d /home/vendetta/Desktop
install -m 0755 /usr/share/applications/vendetta-install.desktop /home/vendetta/Desktop/vendetta-install.desktop
chown -R vendetta:vendetta /home/vendetta

systemctl set-default graphical.target
systemctl enable sddm.service
systemctl disable systemd-networkd.service systemd-networkd.socket iwd.service 2>/dev/null || true
systemctl enable NetworkManager.service
systemctl enable vendetta-avatar.service 2>/dev/null || true

systemctl mask NetworkManager-wait-online.service 2>/dev/null || true

fc-cache -f >/dev/null 2>&1 || true
