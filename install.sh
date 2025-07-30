#!/bin/bash

set -e

WEBOS_URL="https://allucat1000.github.io/HuopaOS"
USERNAME="$(whoami)"

echo "[1/7] Installing packages..."
sudo apt update
sudo apt install -y \
  xserver-xorg \
  x11-xserver-utils \
  xinit \
  chromium-browser \
  lightdm \
  policykit-1 \
  fonts-dejavu \
  unclutter \
  sudo

echo "[2/7] Setting up auto-login..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

sudo systemctl daemon-reexec
sudo systemctl restart getty@tty1

echo "[3/7] Creating .xinitrc..."
cat <<EOF > ~/.xinitrc
#!/bin/bash
xset s off        # disable screen saver
xset -dpms        # disable power management
xset s noblank    # don't blank the video device
unclutter &       # hide mouse cursor after idle
chromium-browser --kiosk --force-device-scale-factor=0.75 "$WEBOS_URL"
EOF

chmod +x ~/.xinitrc

echo "[4/7] Adding startx to .bash_profile..."
if ! grep -q "startx" ~/.bash_profile 2>/dev/null; then
cat <<'EOF' >> ~/.bash_profile

if [[ -z "$DISPLAY" ]] && [[ "$(tty)" = /dev/tty1 ]]; then
  startx
fi
EOF
fi

echo "[5/7] Disabling LightDM (if enabled)..."
sudo systemctl disable lightdm || true

echo "[6/7] Disabling screen blanking..."
sudo sed -i '/^#.*BLANK_TIME/ s/^#//' /etc/kbd/config || true
sudo sed -i 's/^BLANK_TIME=.*/BLANK_TIME=0/' /etc/kbd/config || true

echo "[7/7] Done! Rebooting..."
sleep 2
sudo reboot
