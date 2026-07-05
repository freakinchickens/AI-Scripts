#!/usr/bin/env bash
set -e

echo "=== Updating Void Linux Package Repositories ==="
sudo xbps-install -Syu

echo "=== Installing Build Dependencies ==="
sudo xbps-install -y git xtools void-repo-multilib void-repo-nonfree Base-devel go quickshell niri greetd

echo "=== Setting up Void Source Packages (xbps-src) ==="
if [ ! -d "$HOME/void-packages" ]; then
    git clone --depth=1 https://github.com "$HOME/void-packages"
    cd "$HOME/void-packages"
    ./xbps-src binary-bootstrap
else
    cd "$HOME/void-packages"
    git pull
fi

echo "=== Injecting dani-77's Dank Linux Void Templates ==="
git clone --depth=1 https://github.com /tmp/srcpkgs-d77
cp -r /tmp/srcpkgs-d77/srcpkgs/* "$HOME/void-packages/srcpkgs/"

echo "=== Compiling and Installing Dank Linux Core Components ==="
# Build and install Dank Material Shell
./xbps-src pkg dms
sudo xbps-install -y --repository hostdir/binpkgs dms

# Build and install Dank Search
./xbps-src pkg danksearch
sudo xbps-install -y --repository hostdir/binpkgs danksearch

# Build and install Dank GOM (System monitor backend)
./xbps-src pkg dgop
sudo xbps-install -y --repository hostdir/binpkgs dgop

echo "=== Generating Initial Desktop Configurations ==="
dms setup

echo "=== Enabling Runit Services ==="
# Set up greetd to handle your Wayland session login
if [ ! -L /var/service/greetd ]; then
    sudo ln -s /etc/sv/greetd /var/service/
fi

echo "=== Installation Complete! ==="
echo "Please configure /etc/greetd/config.toml to use niri or Hyprland with DMS."
