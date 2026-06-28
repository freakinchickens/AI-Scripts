#!/usr/bin/env bash
set -e

# --- CONFIGURATION (Adjust as needed) ---
TARGET_DISK="/dev/sda"
HOSTNAME="void-box"
USERNAME="freakinchickens"
PASSWORD="robert" # Change this immediately after boot
TIMEZONE="America/Chicago"
KEYMAP="us"
# ----------------------------------------

echo "=== 1. Partitioning Disk (${TARGET_DISK}) ==="
# Wipe existing partition table and create GPT
parted -s "${TARGET_DISK}" mklabel gpt
# 1. EFI Boot Partition (1GB)
parted -s "${TARGET_DISK}" mkpart primary fat32 1MiB 1025MiB
parted -s "${TARGET_DISK}" set 1 esp on
# 2. Root Partition (Remainder)
parted -s "${TARGET_DISK}" mkpart primary ext4 1025MiB 100%

# Define partition paths (Handles NVMe suffix 'p')
if [[ "${TARGET_DISK}" == *nvme* || "${TARGET_DISK}" == *mmcblk* ]]; then
    BOOT_PART="${TARGET_DISK}p1"
    ROOT_PART="${TARGET_DISK}p2"
else
    BOOT_PART="${TARGET_DISK}1"
    ROOT_PART="${TARGET_DISK}2"
fi

echo "=== 2. Formatting Partitions ==="
mkfs.vfat -F 32 "${BOOT_PART}"
mkfs.ext4 -F "${ROOT_PART}"

echo "=== 3. Mounting File Systems ==="
mkdir -p /mnt
mount "${ROOT_PART}" /mnt
mkdir -p /mnt/boot/efi
mount "${BOOT_PART}" /mnt/boot/efi

echo "=== 4. Bootstrapping Void Linux Base ==="
# Install essential system packages into the mount directory
XBPS_ARCH=x86_64 xbps-install -S -R 
 -r /mnt base-system grub-x86_64-efi NetworkManager

echo "=== 5. Generating fstab ==="
# Find UUIDs to avoid hardcoded drive paths
ROOT_UUID=$(blkid -s UUID -o value "${ROOT_PART}")
BOOT_UUID=$(blkid -s UUID -o value "${BOOT_PART}")

mkdir -p /mnt/etc
cat << EOF > /mnt/etc/fstab
UUID=${ROOT_UUID} / ext4 defaults 0 1
UUID=${BOOT_UUID} /boot/efi vfat defaults 0 2
tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
EOF

echo "=== 6. Configuring System Settings inside Chroot ==="
# Mount pseudofs systems into the target installation
for dir in dev proc sys run; do mount --mkdir --bind /$dir /mnt/$dir; done

xchroot /mnt /bin/bash << CHROOT_EOF
set -e

# Set hostname
echo "${HOSTNAME}" > /etc/hostname

# Set locale and keymap
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/rc.conf

# Set Timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Configure Locales
echo "en_US.UTF-8 UTF-8" >> /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

# Set root password
echo "root:${PASSWORD}" | chpasswd

# Create standard user account
useradd -m -g users -G wheel,audio,video,kvm,input -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${PASSWORD}" | chpasswd

# Allow wheel group to use sudo
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# Enable basic networking daemon
ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/

# Install and configure GRUB Bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void-GRUB" --recheck
xbps-reconfigure -f linux

CHROOT_EOF

echo "=== 7. Cleaning Up ==="
umount -R /mnt

echo "=== SUCCESS: Void Linux installed. Remove install media and reboot! ==="
