#!/usr/bin/env bash
set -euo pipefail

# Define variables
REPO_DIR="$HOME/void-packages"
PKG_NAME="${1:-}"

# Ensure a package name was provided
if [ -z "$PKG_NAME" ]; then
    echo "❌ Error: Please specify a package to build."
    echo "Usage: $0 <package_name>"
    exit 1
fi

# 1. Install required host dependencies
echo "⚙️ Installing build host prerequisites..."
sudo xbps-install -Sy git curl flock tar git

# 2. Clone the void-packages repository if missing
if [ ! -d "$REPO_DIR" ]; then
    echo "📥 Cloning void-packages repository..."
    git clone --depth=1 https://github.com/void-linux/void-packages.git "$REPO_DIR"
else
    echo "🔄 Repository already exists. Syncing upstream updates..."
    cd "$REPO_DIR"
    git pull
fi

cd "$REPO_DIR"

# 3. Bootstrap the isolated chroot masterdir environment
if [ ! -d "masterdir" ]; then
    echo "🥾 Initializing binary bootstrap container..."
    ./xbps-src binary-bootstrap
fi

# 4. Optional: Enable restricted repositories (e.g., Google Chrome, Discord)
# Uncomment the line below if you are building proprietary software templates
# echo "XBPS_ALLOW_RESTRICTED=yes" >> etc/conf

# 5. Build the requested package from source
echo "🔨 Compiling '$PKG_NAME' from source template..."
./xbps-src pkg "$PKG_NAME"

# 6. Install the freshly compiled package to the local system
echo "📦 Installing locally generated package..."
sudo xbps-install -y --repository=hostdir/binpkgs "$PKG_NAME"

echo "✅ Successfully built and installed $PKG_NAME!"
