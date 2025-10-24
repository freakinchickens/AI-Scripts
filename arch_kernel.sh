#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define kernel source directory and output directory
KERNEL_VERSION="6.9.1" # Adjust to your desired kernel version
KERNEL_SOURCE_DIR="/usr/src/linux-${KERNEL_VERSION}"
BUILD_DIR="/tmp/kernel_build"
OUTPUT_PKG_DIR="/tmp/kernel_packages"

# 1. Install necessary build tools
echo "Installing necessary build tools..."
sudo pacman -S --noconfirm base-devel git bc cpio perl python-setuptools xmlto asciidoc elfutils libmpc zstd

# 2. Download kernel source if not already present
if [ ! -d "$KERNEL_SOURCE_DIR" ]; then
    echo "Downloading kernel source for version ${KERNEL_VERSION}..."
    sudo pacman -S --noconfirm linux-headers # Ensure headers for current kernel are available
    # You might need to manually download a specific kernel version from kernel.org if not in Arch repos
    # Example: wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz
    # tar -xf linux-${KERNEL_VERSION}.tar.xz -C /usr/src/
    # sudo ln -s /usr/src/linux-${KERNEL_VERSION} /usr/src/linux
else
    echo "Kernel source for version ${KERNEL_VERSION} already present."
fi

# 3. Create build directory
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_PKG_DIR"
cd "$BUILD_DIR"

# 4. Configure the kernel
echo "Configuring the kernel..."
# Copy the existing kernel configuration as a base
cp "/proc/config.gz" "config.gz"
gunzip "config.gz"
mv "config" ".config"

# Merge new options from the kernel source
make O="$BUILD_DIR" olddefconfig

# Optional: Manual configuration using menuconfig (uncomment to enable)
# make O="$BUILD_DIR" menuconfig

# Enable AMD-specific optimizations in .config (example, adjust as needed)
# Ensure these lines are present and set to 'y' or 'm' in your .config
# CONFIG_X86_AMD_K8="y"
# CONFIG_MICROCODE_AMD="y"
# CONFIG_DRM_AMDGPU="y"
# CONFIG_DRM_AMDGPU_SI="y"
# CONFIG_DRM_AMDGPU_CIK="y"
# CONFIG_DRM_AMDGPU_POLARIS="y"
# CONFIG_DRM_AMDGPU_VEGA="y"
# CONFIG_DRM_AMDGPU_NAVI="y"

# 5. Build the kernel and modules
echo "Building the kernel and modules..."
make O="$BUILD_DIR" -j$(nproc)

# 6. Build and install kernel packages
echo "Building Arch Linux kernel packages..."
# This step assumes you are building from the standard Arch Linux kernel PKGBUILD
# For a custom kernel, you would typically create your own PKGBUILD or use 'make install'
# This example uses 'makepkg' for a more Arch-native package creation
# You would need to adapt this if you're not using the Arch kernel source with its PKGBUILD
# For a custom kernel, you might do:
# sudo make O="$BUILD_DIR" modules_install
# sudo make O="$BUILD_DIR" install

# If you want to create Arch packages, you'd typically copy the Arch kernel PKGBUILD
# and modify it, then run makepkg. This is a more involved process.
# For simplicity, this script demonstrates a direct build and install (commented out)
# For creating Arch packages, you would typically:
# 2. Modify the PKGBUILD for your custom kernel (e.g., source, config).
# 3. Run 'makepkg -s' in the directory with the PKGBUILD.

# For direct installation (less ideal for Arch, but simpler for custom kernels):
echo "Installing the new kernel and modules directly (consider using Arch packages for better management)..."
sudo make O="$BUILD_DIR" modules_install
sudo make O="$BUILD_DIR" install

# 7. Update GRUB configuration
echo "Updating GRUB configuration..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Kernel compilation and installation complete. Please reboot to use the new kernel."
