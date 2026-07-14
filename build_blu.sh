#!/bin/bash
# ==============================================================================
# blu_spark Kernel Build Script for Google 'Pantah' (Pixel 7/Pro) on Arch Linux
# Compiles engstk's custom optimized kernel layout using the Kleaf build framework.
# ==============================================================================

set -e # Terminate script immediately on failure

# 1. Configuration & Directories
BUILD_DIR="$HOME/blu_spark_pantah"
MANIFEST_BRANCH="android17-6.1"      # Targets Android 17 (Tensor 6.1 GKI base)
JOBS=$(nproc)
CUSTOM_OUT_DIR="$HOME/Desktop/blu_spark_out"

echo "==> [1/5] Syncing Arch Linux base development headers..."
sudo pacman -Sy --needed --noconfirm \
    base-devel git curl rsync lz4 xz zstd bc libelf openssl \
    python python-pip perl unrar unzip zip android-tools

# Validate or pull the Android Repo Manifest wrapper
if ! command -v repo &> /dev/null; then
    echo "==> Pulling stand-alone repo executable binary..."
    mkdir -p "$HOME/bin"
    curl https://googleapis.com > "$HOME/bin/repo"
    chmod a+x "$HOME/bin/repo"
    export PATH="$HOME/bin:$PATH"
fi

# 2. Workspace Initialization
echo "==> [2/5] Constructing clean directory structures..."
mkdir -p "$BUILD_DIR"
mkdir -p "$CUSTOM_OUT_DIR"
cd "$BUILD_DIR"

# 3. Download Source & Swap to blu_spark Repository Trees
if [ ! -d ".repo" ]; then
    echo "==> Initializing vanilla Android 17 kernel manifest..."
    repo init -u https://googlesource.com -b "$MANIFEST_BRANCH" --depth=1
else
    echo "==> Repo manifests already exist. Moving forward."
fi

echo "==> Syncing files from upstream (This might take a while)..."
repo sync -j"$JOBS" --current-branch --no-tags --force-sync

echo "==> [3/5] Injecting blu_spark custom device repositories..."
# Wipe the default Google device directory if present to drop in engstk's optimized tree
rm -rf private/devices/google/pantah

# Clone the custom blu_spark hardware configurations directly into your source tree
git clone https://github.com -b android17 private/devices/google/pantah --depth=1

# 4. Trigger the Custom Compilation
echo "==> [4/5] Launching Bazel hermetic compilation via Kleaf..."
export BUILD_AOSP_KERNEL=1

# Compiles using blu_spark flags while accounting for Arch Python sandbox configurations
tools/bazel run --host_action_env=PATH \
    //private/devices/google/pantah:pantah_dist \
    --config=stamp \
    --lto=thin \
    -- --destdir="$CUSTOM_OUT_DIR"

# 5. Execution Summary
echo "==> [5/5] blu_spark Compilation Sequence Succeeded!"
echo "Flashable artifacts (`Image`, `dtbo.img`) have been successfully exported to:"
echo "    $CUSTOM_OUT_DIR"
echo "--------------------------------------------------------"
ls -lh "$CUSTOM_OUT_DIR"
