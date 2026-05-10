#!/bin/bash

set -euo pipefail

# Root Function
if [[ $EUID -eq 0 ]]; then
    echo "Do not run as root!" >&2
    exit 1
fi

# Add contrib, non-free and non-free-firmware repositories
if ! grep -q " contrib" /etc/apt/sources.list; then
    echo "Adding contrib, non-free, non-free-firmware..."
    sudo sed -i 's/ main/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt-get update
else
    echo "Repositories already configured"
fi

# User detection
echo "User is: $USER"
sleep 2

# Package Update
sudo apt-get update && sudo apt-get upgrade

# Packages
core=(
    build-essential gcc vim tmux
    i3 i3status i3lock libnotify-bin feh
    pulseaudio pulseaudio-utils alsa-utils pavucontrol
    xfce4-terminal picom lxappearance dunst
    j4-dmenu-desktop brightnessctl xorg xinit x11-server-utils
    xdg-utils xdg-user-dirs network-manager flameshot xclip
    mpv git curl wget unzip gvfs-backends thunar thunar-volman 
    ffmpeg ffmpegthumbnailer mousepad redshift polkitd
)

echo "Installing core packages..."
sleep 1

sudo apt install -y "${core[@]}"

# Explicitly remove nano

sudo apt autoremove nano 2>/dev/null || echo "Nano is already removed, or was manually removed. Continuing..."

echo "Installing Brave Origin..."

sudo curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg && sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-nightly.sources https://brave-browser-apt-nightly.s3.brave.com/brave-browser.sources

sudo apt-get update

sudo apt-get install brave-origin-nightly

# Services & Reloads
xdg-user-dirs-update
systemctl --user enable pulseaudio.service
sudo sed -i 's/^[^#]/#&/' /etc/network/interfaces
sudo sed -i 's/^managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf

echo "Installation Complete. System will reboot in:"

for i in {5..1}; do
    echo "$i..."
    sleep 1
done

sudo reboot
