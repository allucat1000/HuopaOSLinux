#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

USERNAME="huopaos"

# Update system and install essential packages
pacman -Syu --noconfirm
pacman -S --noconfirm xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xprop openbox git

# Install snapd
pacman -S --noconfirm snapd
systemctl enable --now snapd.socket

# Enable classic snap support
ln -s /var/lib/snapd/snap /snap

# Install Chromium via Snap
sudo -u $USERNAME snap install chromium

# Setup .xinitrc for the user
cat <<EOF > /home/$USERNAME/.xinitrc
#!/bin/bash
sleep 1
exec openbox-session &
exec /snap/bin/chromium --force-dark-mode --kiosk --force-device-scale-factor=0.75 https://allucat1000.github.io/HuopaOS
EOF
chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc
chmod +x /home/$USERNAME/.xinitrc

# Setup auto-login on tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

# Auto-start X on login
echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> /home/$USERNAME/.bash_profile
chown $USERNAME:$USERNAME /home/$USERNAME/.bash_profile

echo "Setup complete. Reboot to start in Chromium kiosk mode."
