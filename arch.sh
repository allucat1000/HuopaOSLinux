#!/bin/bash

USERNAME="huopaos"

# Update system and install essential packages
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm base-devel git xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xprop openbox

# Build and install snapd from AUR
TMPDIR=$(mktemp -d)
git clone https://aur.archlinux.org/snapd.git "$TMPDIR/snapd"
cd "$TMPDIR/snapd" || exit 1
makepkg -si --noconfirm
cd /
rm -rf "$TMPDIR"

# Enable snapd
sudo systemctl enable --now snapd.socket

# Enable classic snap support
sudo ln -sf /var/lib/snapd/snap /snap

# Wait a bit for snapd to settle
sleep 5

# Install Chromium via Snap as the user
sudo snap install chromium

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
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

# Auto-start X on login
echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> /home/$USERNAME/.bash_profile
chown $USERNAME:$USERNAME /home/$USERNAME/.bash_profile

echo "Setup complete. Reboot to start in Chromium kiosk mode."
