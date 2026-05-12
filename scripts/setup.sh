#!/bin/bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Do not run as root!" >&2
    exit 1
fi

echo "Starting installation in:"

for n in {5..1}; do
    echo "$n..."
    sleep 1
done

if ! grep -q " contrib" /etc/apt/sources.list; then
    echo "Adding contrib, non-free, non-free-firmware..."
    sleep 3
    sudo sed -i 's/ main/ main contrib non-free non-free-firmware/' /etc/apt/sources.list
    sudo apt-get update
else
    echo "Repositories already configured"
    sleep 2
fi

clear 


echo "User is: $USER"
sleep 2


sudo apt-get update && sudo apt-get upgrade -y

while true; do
    read -p "Install NVIDIA Driver? y/n " confirm
        case "$confirm"; in
            [yY] | "")
                clear
                echo "Installing NVIDIA drivers..."
                sleep 2
                sudo apt-get install -y linux-headers-generic \
                    build-essential nvidia-detect
                clear
                nvidia-detect
                sudo apt-get install -y nvidia-driver
                clear
                echo "NVIDIA driver has been installed."
                sleep 2
                break
                ;;
            [nN])
                echo "Not installing NVIDIA drivers..."
                sleep 1
                clear
                break
                ;;
            *)
                echo "Invalid input. Try again. (y/n)"
                ;;
         esac
    done

packages=(
    gcc git vim tmux \
        fonts-noto fonts-noto-cjk fonts-noto-cjk-extra fonts-noto-color-emoji \
        fonts-noto-core ttf-mscorefonts-installer \
        i3 i3status i3lock j4-dmenu-desktop picom dunst feh brightnessctl \
        xorg xinit x11-server-utils pulseaudio pulseaudio-utils alsa-utils \
        pavucontrol lxappearace arc-theme papirus-icon-theme network-manager \
        unzip xdg-utils xdg-user-dirs polkitd gvfs-backends thunar thunar-volman \
        ffmpegthumbnailer ffmpeg mpv mousepad redshift flameshot xclip libnotify-bin obs-studio
)

echo "Installing packages..."
sleep 1

sudo apt-get install -y "${packages[@]}"
    
echo "Installation Complete."
sleep 2
clear

echo "Installing Ghostty..."
sleep 2

curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg && echo "deb https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list

sudo apt-get update && sudo apt-get install ghostty -y
echo "Ghostty installed."
sleep 1
clear

sudo apt purge nano -y 2>/dev/null || echo "Nano is already removed, or was manually removed. Continuing..."

font_dir="$HOME/.local/share/fonts"
mkdir -p "$font_dir"

nf_urls="/tmp/fonts.txt"
cat > "$nf_urls" << 'EOF'
https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/MartianMono.zip
https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/IosevkaTerm.zip
https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/GeistMono.zip
https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip
EOF

cd "$font_dir"
echo "Downloading Nerd Fonts...(this might take a while)"
sleep 2
wget --show-progress -i "$nf_urls" 

echo "Download complete. Extracting fonts..."
sleep 2

for zip in ./*.zip; do
    [ -f "$zip" ] && unzip -o "$zip"
done

echo "Extraction complete. Refreshing font cache, cleanup..." 
sleep 2

fc-cache -fv && rm -f ./*.zip
rm -f "$nf_urls"
echo "Nerd Fonts have been installed."

cd "$HOME"
sleep 2
clear 

echo "Installing Brave Origin..."

sudo curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg && sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-nightly.sources https://brave-browser-apt-nightly.s3.brave.com/brave-browser.sources

sudo apt-get update

sudo apt-get install brave-origin-nightly -y

clear

echo "Adding bash-git-prompt..."
sleep 1
git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1

tee -a "$HOME/.bashrc" << 'EOF'

if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_ONLY_IN_REPO=1
    source "$HOME/.bash-git-prompt/gitprompt.sh"
fi
EOF

sleep 1
echo "Cloning homeguard..."
git clone "https://github.com/jgz365/homeguard.git" "$HOME/homeguard"

mkdir -p "$HOME/.config/i3/"
mkdir -p "$HOME/.config/i3status/"
mkdir -p "$HOME/.config/ghostty/"
mkdir -p "$HOME/.config/fastfetch/"
mkdir -p "$HOME/.config/dunst/"
mkdir -p "$HOME/.config/picom/"

cp -r "$HOME/homeguard/i3/" "$HOME/.config/"
cp -r "$HOME/homeguard/i3status/" "$HOME/.config/"
cp -r "$HOME/homeguard/ghostty/" "$HOME/.config/"
cp -r "$HOME/homeguard/fastfetch/" "$HOME/.config/"
cp -r "$HOME/homeguard/dunst/" "$HOME/.config/"
cp -r "$HOME/homeguard/picom/" "$HOME/.config/"

cp "$HOME/homeguard/.vimrc" "$HOME"

rm -rf "$HOME/homeguard"

echo "Dotfiles are set."
sleep 1
clear

echo "Performing system services..."
sleep 2

xdg-user-dirs-update
echo "exec dbus-run-session i3" >> "$HOME/.xinitrc"
systemctl --user enable pulseaudio.service

if grep -qv '^#' /etc/network/interfaces; then
    sudo sed -i '/^[^#]/s/^/#/' /etc/network/interfaces
fi

sudo sed -i 's/^managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf

clear
echo "Don't forget to connect to the internet with 'nmtui'"
sleep 3

echo "Installation Complete. System will reboot in:"

for i in {5..1}; do
    echo "$i..."
    sleep 1
done

systemctl reboot
