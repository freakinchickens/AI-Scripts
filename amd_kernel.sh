#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
KERNEL_VERSION="6.13.3"
KERNEL_URL="https://kernel.org{KERNEL_VERSION}.tar.xz"
BUILD_DIR="${HOME}/amd_kernel_build"
# ---------------------

echo "=== 1. Creating Build Directory ==="
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "=== 2. Downloading Kernel Sources ==="
if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
    curl -L -O "${KERNEL_URL}"
fi

echo "=== 3. Extracting Linux Kernel ==="
rm -rf "linux-${KERNEL_VERSION}"
tar -xf "linux-${KERNEL_VERSION}.tar.xz"
cd "linux-${KERNEL_VERSION}"

echo "=== 4. Seeding Base Configuration ==="
if [ -f "/boot/config-$(uname -r)" ]; then
    cp "/boot/config-$(uname -r)" .config
else
    make defconfig
fi

echo "=== 5. Optimizing Configuration for AMD Only ==="
# Disable Intel-specific CPU features and microcode
scripts/config --disable CONFIG_CPU_SUP_INTEL
scripts/config --disable CONFIG_MICROCODE_INTEL
scripts/config --disable CONFIG_X86_INTEL_LPSS
scripts/config --disable CONFIG_X86_INTEL_PSTATE
scripts/config --disable CONFIG_INTEL_IDLE
scripts/config --disable CONFIG_CPU_SUP_CENTAUR
scripts/config --disable CONFIG_CPU_SUP_ZHAOXIN

# Enable AMD-specific features
scripts/config --enable CONFIG_CPU_SUP_AMD
scripts/config --enable CONFIG_MICROCODE_AMD
scripts/config --enable CONFIG_X86_AMD_PLATFORM_DEVICE
scripts/config --enable CONFIG_AMD_NB
scripts/config --enable CONFIG_X86_AMD_FREQ_SENSITIVITY

# Optimize compilation flags for your specific AMD CPU architecture
scripts/config --disable CONFIG_GENERIC_CPU
scripts/config --enable CONFIG_MNATIVE

# Apply configuration changes
make olddefconfig

echo "=== 6. Compiling Kernel (AMD Optimized) ==="
# KCFLAGS="-march=native" forces GCC to optimize instructions for your exact AMD Ryzen/EPYC model
make KCFLAGS="-march=native" -j$(nproc)

echo "=== 7. Installing Kernel and Modules ==="
sudo make modules_install
sudo make install

echo "=== 8. Updating Bootloader ==="
if command -v grub-mkconfig >/dev/null 2>&1; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
elif command -v update-grub >/dev/null 2>&1; then
    sudo update-grub
fi

echo "=== SUCCESS: AMD-only Kernel compiled and installed ==="
