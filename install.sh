#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

USERNAME="huopaos"

# Update system and install packages
apt update
apt install -y x11-utils xserver-xorg xinit x11-xserver-utils chromium openbox

# Setup .xinitrc for the user
cat <<EOF > /home/$USERNAME/.xinitrc
#!/bin/bash
sleep 1
exec openbox-session &
exec chromium --force-dark-mode --kiosk --force-device-scale-factor=0.75 https://allucat1000.github.io/HuopaOS
EOF
chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc
chmod +x /home/$USERNAME/.xinitrc

# Setup auto-login
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

# Auto-start X on login
echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> /home/$USERNAME/.bash_profile
chown $USERNAME:$USERNAME /home/$USERNAME/.bash_profile

# Removing virtual desktop keybinds
mkdir -p /home/$USERNAME/.config/openbox

if [ ! -f /home/$USERNAME/.config/openbox/rc.xml ]; then
  cp /etc/xdg/openbox/rc.xml /home/$USERNAME/.config/openbox/rc.xml
fi

sed -i 's|<number>[0-9]\+</number>|<number>1</number>|' /home/$USERNAME/.config/openbox/rc.xml

# Remove Ctrl+Alt+Arrow keybinds
sed -i '/<keybind key="C-A-Left">/,/<\/keybind>/d' /home/$USERNAME/.config/openbox/rc.xml
sed -i '/<keybind key="C-A-Right">/,/<\/keybind>/d' /home/$USERNAME/.config/openbox/rc.xml
sed -i '/<keybind key="C-A-Up">/,/<\/keybind>/d' /home/$USERNAME/.config/openbox/rc.xml
sed -i '/<keybind key="C-A-Down">/,/<\/keybind>/d' /home/$USERNAME/.config/openbox/rc.xml

# Set ownership to user
chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/openbox

echo "Setup complete. Reboot to start in Chromium kiosk mode."
