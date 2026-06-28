#!/usr/bin/env bash
set -e

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root (sudo)."
  exit 1
fi

echo "=== 1. Syncing Portage Tree ==="
emaint sync -r gentoo

echo "=== 2. Accepting Zen Kernel Keywords (if testing) ==="
# This ensures Portage can find the zen-sources package
mkdir -p /etc/portage/package.accept_keywords
echo "sys-kernel/zen-sources ~amd64" > /etc/portage/package.accept_keywords/zen-sources

echo "=== 3. Installing Zen Kernel Sources ==="
emerge --ask=n sys-kernel/zen-sources

echo "=== 4. Setting Up Kernel Configuration ==="
# Set the symlink /usr/src/linux to point to the new zen-sources
eselect kernel set $(eselect kernel list | grep "zen-sources" | awk -F'[][]' '{print $2}' | tail -n 1)

# Navigate to kernel source directory
cd /usr/src/linux

echo "=== 5. Compiling and Installing Kernel ==="
# Using distribution default configuration as a safe baseline
make defconfig

# Compile and install the kernel, modules, and device tree (if applicable)
make -j$(nproc)
make modules_install
make install

echo "=== 6. Updating Bootloader Configuration ==="
if [ -d /boot/grub ]; then
    echo "Updating GRUB configuration..."
    grub-mkconfig -o /boot/grub/grub.cfg
elif command -v bootctl >/dev/null 2>&1; then
    echo "Systemd-boot detected. Please verify your loader entries."
fi

echo "=== SUCCESS: Zen Kernel compiled and installed. Reboot to use it! ==="
