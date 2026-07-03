#!/bin/bash

# Define paths relative to the repo root
export ROOT_DIR=$(pwd)
export OUT_DIR="${ROOT_DIR}/out"
export DIST_DIR="${ROOT_DIR}/dist"

# Specify the core GKI configurations
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export BUILD_CONFIG="common/build.config.gki.aarch64"

# Set up toolchain defaults
export CC=clang
export LD=ld.lld

# Clean previous build directories if needed
rm -rf "$OUT_DIR" "$DIST_DIR"

# Call the official AOSP build script
echo "Starting AOSP GKI Build..."
./build/build.sh

echo "Build complete. Artifacts are in: $DIST_DIR"
