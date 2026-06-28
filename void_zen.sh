#!/usr/bin/env bash
set -e

# 1. Define the target Zen Kernel version
KERNEL_VERSION="6.13"
PATCH_VERSION="6.13.3-zen1" # Change this based on the current Zen release tag
PATCH_URL="https://github.com{PATCH_VERSION}/linux-v${PATCH_VERSION}.patch.zst"

echo "=== Installing dependencies ==="
sudo xbps-install -Sy git base-devel xtools zstd

echo "=== Setting up void-packages repository ==="
if [ ! -d "void-packages" ]; then
    git clone --depth=1 https://github.com/void-linux/void-packages.git
fi
cd void-packages
./xbps-src binary-bootstrap

echo "=== Creating Zen Kernel XBPS template ==="
cd srcpkgs
# Copy the existing mainline kernel template to create the Zen variant
cp -a "linux${KERNEL_VERSION}" "linux${KERNEL_VERSION}-zen"

# Create required symbolic links for headers and debug symbols
ln -sf "linux${KERNEL_VERSION}-zen" "linux${KERNEL_VERSION}-zen-headers"
ln -sf "linux${KERNEL_VERSION}-zen" "linux${KERNEL_VERSION}-zen-dbg"

echo "=== Downloading and extracting Zen patch ==="
mkdir -p "linux${KERNEL_VERSION}-zen/patches"
cd "linux${KERNEL_VERSION}-zen/patches"
curl -L -O "${PATCH_URL}"
zstd -d linux-v${PATCH_VERSION}.patch.zst
rm linux-v${PATCH_VERSION}.patch.zst

echo "=== Updating package template metadata ==="
cd ../.. # Back to void-packages/srcpkgs
# Adjust package configuration names inside the template
sed -i "s/pkgname=linux${KERNEL_VERSION}/pkgname=linux${KERNEL_VERSION}-zen/g" "linux${KERNEL_VERSION}-zen/template"

echo "=== Generating template checksums ==="
cd .. # Back to void-packages root
xgensum -i "linux${KERNEL_VERSION}-zen"

echo "=== Compiling Zen Kernel (This will take a while) ==="
./xbps-src pkg -j$(nproc) "linux${KERNEL_VERSION}-zen"

echo "=== Installing the compiled Zen Kernel package ==="
xi "linux${KERNEL_VERSION}-zen" "linux${KERNEL_VERSION}-zen-headers"

echo "=== Updating bootloader configuration ==="
sudo xbps-reconfigure -f "linux${KERNEL_VERSION}-zen"

echo "=== SUCCESS: Please reboot your system and select the Zen Kernel ==="
