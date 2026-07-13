#!/bin/bash
# ==============================================================================
# Android 17 Kernel Build Script for Google 'Pantah' (Pixel 7/Pro) on Arch Linux
# Compiles kernel and routes artifacts to a custom designated output folder.
# ==============================================================================

set -e # Exit immediately on error

# 1. Define Variables
BUILD_DIR="$HOME/android_kernel_pantah"
MANIFEST_BRANCH="android17-6.1" # Android 17 utilizes 6.1 GKI / Tensor branches
JOBS=$(nproc)

# --- CONFIGURABLE CUSTOM OUTPUT FOLDER ---
# Change this path to wherever you want your final flashable files moved
CUSTOM_OUT_DIR="$HOME/Desktop/my_pantah_kernel_build"
# =========================================

echo "==> [1/5] Installing Arch Linux host dependencies..."
sudo pacman -Sy --needed --noconfirm \
    base-devel git curl rsync lz4 xz zstd bc libelf openssl \
    python python-pip perl unrar unzip zip android-tools

# Ensure repo command tool exists
if ! command -v repo &> /dev/null; then
    echo "==> Repo tool not found, downloading to ~/bin..."
    mkdir -p "$HOME/bin"
    curl https://googleapis.com > "$HOME/bin/repo"
    chmod a+x "$HOME/bin/repo"
    export PATH="$HOME/bin:$PATH"
fi

# 2. Setup Working Directory
echo "==> [2/5] Creating directories..."
mkdir -p "$BUILD_DIR"
mkdir -p "$CUSTOM_OUT_DIR"
cd "$BUILD_DIR"

# 3. Initialize and Sync Source Code
if [ ! -d ".repo" ]; then
    echo "==> [3/5] Initializing Android 17 kernel repository..."
    repo init -u https://googlesource.com -b "$MANIFEST_BRANCH" --depth=1
else
    echo "==> Repo already initialized. Skipping init."
fi

echo "==> Syncing sources (this may take a while)..."
repo sync -j"$JOBS" --current-branch --no-tags --force-sync

# 4. Compile the Kernel via Kleaf (Bazel Wrapper) with Custom Destination
echo "==> [4/5] Starting Pantah kernel compilation via Kleaf..."
export BUILD_AOSP_KERNEL=1

# --destdir flag forces Bazel's distribution rule to copy files to our custom output path.
# We also include --host_action_env=PATH to handle Arch's rolling python system seamlessly.
tools/bazel run --host_action_env=PATH \
    //private/devices/google/pantah:pantah_dist \
    --config=stamp \
    --lto=thin \
    -- --destdir="$CUSTOM_OUT_DIR"

# 5. Build Completion Summary
echo "==> [5/5] Build Completed Successfully!"
echo "Your flashable artifacts have been safely exported to:"
echo "    $CUSTOM_OUT_DIR"
echo "--------------------------------------------------------"
ls -lh "$CUSTOM_OUT_DIR"
