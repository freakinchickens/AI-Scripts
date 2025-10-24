#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to display error messages and exit
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

echo -e "${GREEN}Starting kernel build process...${NC}"

# Ensure we are in the kernel source directory
cd /usr/src/linux || error_exit "Failed to change to kernel source directory."

# Clean up previous build artifacts
echo -e "${YELLOW}Cleaning up old build artifacts...${NC}"
make clean || error_exit "Failed to clean kernel source."
make mrproper || error_exit "Failed to run make mrproper."

# Copy the running kernel's configuration as a starting point
# This is a good starting point for AMD systems as it should include
# necessary drivers and features.
echo -e "${YELLOW}Copying current kernel config...${NC}"
zcat /proc/config.gz > .config || error_exit "Failed to copy current kernel config."

# Update the configuration using 'oldconfig' to prompt for new options
# This is a non-interactive way to update the config based on the old one.
echo -e "${YELLOW}Updating kernel configuration...${NC}"
yes "" | make oldconfig || error_exit "Failed to update kernel configuration."

# Compile the kernel
echo -e "${YELLOW}Compiling the kernel (this may take a while)...${NC}"
# Adjust -jN based on your CPU cores for parallel compilation (e.g., -j$(nproc))
make -j$(nproc) || error_exit "Kernel compilation failed."

# Install the new kernel and modules
echo -e "${YELLOW}Installing the new kernel and modules...${NC}"
make modules_install || error_exit "Failed to install kernel modules."
make install || error_exit "Failed to install the kernel."

# Update GRUB configuration
echo -e "${YELLOW}Updating GRUB configuration...${NC}"
grub-mkconfig -o /boot/grub/grub.cfg || error_exit "Failed to update GRUB configuration."

echo -e "${GREEN}Kernel build and installation complete! Please reboot to use the new kernel.${NC}"
