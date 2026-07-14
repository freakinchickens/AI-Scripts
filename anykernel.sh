#!/bin/bash
# ==============================================================================
# AnyKernel3 Flashable Zip Packager
# Extracts kernel artifacts and bundles them into a recovery-flashable .zip
# ==============================================================================

set -e # Exit immediately on error

# 1. Configuration Paths (Adjust these to match your build setup)
KERNEL_OUT_DIR="$HOME/Desktop/my_pantah_kernel_build" # Where your compiled Image lives
ANYKERNEL_WORKSPACE="$HOME/anykernel_workspace"        # Temporary packing directory
ZIP_OUTPUT_DIR="$HOME/Desktop"                        # Where the final flashable zip drops
ZIP_NAME="AnyKernel3-Pantah-Android17-$(date +%Y%m%d).zip"

echo "==> [1/4] Setting up clean AnyKernel3 workspace..."
rm -rf "$ANYKERNEL_WORKSPACE"
mkdir -p "$ANYKERNEL_WORKSPACE"
mkdir -p "$ZIP_OUTPUT_DIR"

# 2. Clone official AnyKernel3 template
echo "==> [2/4] Cloning AnyKernel3 upstream repository..."
git clone https://github.com "$ANYKERNEL_WORKSPACE" --depth=1

# 3. Configure anykernel.sh for Pixel 7 / Pro (Pantah)
echo "==> [3/4] Modifying anykernel.sh variables for Pantah..."
SED_TARGET="$ANYKERNEL_WORKSPACE/anykernel.sh"

# Update target device parameters for Tensor G2 Pantah (panther/cheetah)
sed -i 's/kernel.string=.*/kernel.string=Custom Android 17 Kernel for Pantah/' "$SED_TARGET"
sed -i 's/do.devicecheck=1/do.devicecheck=1/' "$SED_TARGET"
sed -i 's/device.name1=.*/device.name1=pantah/' "$SED_TARGET"
sed -i 's/device.name2=.*/device.name2=panther/' "$SED_TARGET"
sed -i 's/device.name3=.*/device.name3=cheetah/' "$SED_TARGET"

# Set structural partition blocks for Pixel 7 series dynamic partitions
sed -i 's|block=.*/boot;|block=auto;|' "$SED_TARGET"
sed -i 's/is_slot_device=0/is_slot_device=1/' "$SED_TARGET"

# 4. Copy build artifacts and create the ZIP payload
echo "==> [4/4] Copying kernel components and archiving payload..."

if [ -f "$KERNEL_OUT_DIR/Image" ]; then
    cp "$KERNEL_OUT_DIR/Image" "$ANYKERNEL_WORKSPACE/Image"
else
    echo "❌ ERROR: 'Image' file not found in $KERNEL_OUT_DIR" && exit 1
fi

if [ -f "$KERNEL_OUT_DIR/dtbo.img" ]; then
    cp "$KERNEL_OUT_DIR/dtbo.img" "$ANYKERNEL_WORKSPACE/dtbo.img"
else
    echo "⚠️ WARNING: 'dtbo.img' not found. Skipping DTBO bundling."
fi

# Switch to workspace to prevent directory structures inside the zip
cd "$ANYKERNEL_WORKSPACE"
# Remove internal git markers before compressing
rm -rf .git README.md

# Zip everything cleanly using native Arch Linux zip
zip -r9 "$ZIP_OUTPUT_DIR/$ZIP_NAME" ./*

echo "========================================================"
echo "🎉 SUCCESS: Flashable AnyKernel3 package created!"
echo "📍 Location: $ZIP_OUTPUT_DIR/$ZIP_NAME"
echo "========================================================"
