#!/usr/bin/env bash
set -e

echo "=== 1. Detecting Package Manager and Installing Packages ==="

# Check for Void Linux (XBPS)
if command -v xbps-install >/dev/null 2>&1; then
    echo "Void Linux detected."
    # Niri is in the official Void binary repos.
    sudo xbps-install -Sy niri alacritty fuzzel waybar mako swaybg \
                         dbus elogind seatd xdg-desktop-portal-gnome \
                         xwayland-satellite PipeWire wireplumber
    
    # Enable vital Wayland system services on Void if not already enabled
    sudo ln -sf /etc/sv/dbus /var/service/
    sudo ln -sf /etc/sv/elogind /var/service/
    sudo ln -sf /etc/sv/seatd /var/service/
    # Ensure current user is in the 'video' and 'input' groups for seatd
    sudo usermod -aG video,input "$USER"

# Check for Arch Linux (Pacman)
elif command -v pacman >/dev/null 2>&1; then
    echo "Arch Linux detected."
    sudo pacman -Syu --noconfirm niri alacritty fuzzel waybar mako swaybg \
                                 xdg-desktop-portal-gnome xwayland-satellite \
                                 pipewire pipewire-pulse wireplumber

# Check for Fedora (DNF)
elif command -v dnf >/dev/null 2>&1; then
    echo "Fedora Linux detected."
    sudo dnf install -y niri alacritty fuzzel waybar mako swaybg \
                       xdg-desktop-portal-gnome xwayland-satellite \
                       pipewire-utils wireplumber
else
    echo "Unsupported distribution. Exiting."
    exit 1
fi

echo "=== 2. Creating Configurations ==="
# Create default configuration directory
mkdir -p "${HOME}/.config/niri"

# If config doesn't exist, we seed a basic multi-file layout starter structure
if [ ! -f "${HOME}/.config/niri/config.kdl" ]; then
    echo "Generating basic config.kdl layout..."
    cat << 'EOF' > "${HOME}/.config/niri/config.kdl"
// Niri Main Configuration (KDL format)

input {
    keyboard {
        xkb {
            layout "us"
        }
    }
    touchpad {
        tap
        natural-scroll
    }
}

output "eDP-1" {
    mode "1920x1080@60.000"
    scale 1.0
}

// Wayland Startup Services
spawn-at-startup "waybar"
spawn-at-startup "mako"
spawn-at-startup "swaybg" "-m" "solid" "-c" "#1e1e2e"
spawn-at-startup "xwayland-satellite"

// Preferred Settings
prefer-no-csd

// Bindings
binds {
    // Super + T opens the default terminal
    Mod+T { spawn "alacritty"; }
    // Super + D opens the application launcher
    Mod+D { spawn "fuzzel"; }
    // Super + Shift + E exits Niri
    Mod+Shift+E { quit; }
    
    // Window Management
    Mod+Left  { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Down  { focus-window-down; }
    Mod+Up    { focus-window-up; }
    
    Mod+Shift+Left  { move-column-left; }
    Mod+Shift+Right { move-column-right; }
    
    Mod+R { switch-preset-column-width; }
    Mod+F { maximize-column; }
    Mod+C { close-window; }
}
EOF
fi

echo "=== SUCCESS ==="
echo "If you use a display manager (GDM/LightDM), restart it to see Niri."
echo "If starting from TTY, run: niri --session"
```

### Installed Wayland Tool Ecosystem

Niri handles window management exclusively, meaning companion tools are required to manage your overall user space:
* **Terminal Emulator (`alacritty`)**: A fast, GPU-accelerated terminal that interfaces perfectly with Wayland protocols.
* **Application Launcher (`fuzzel`)**: A Wayland-native, pixel-perfect dynamic menu used for typing out and launching application binaries.
* **Status Bar (`waybar`)**: Provides an informational top bar showing workspace indices, system trays, battery status, and date timers.
* **Notification Daemon (`mako`)**: A lightweight notification banner manager styled specifically for Wayland compositors.
* **X11 Legacy Compatibility (`xwayland-satellite`)**: Runs a background server that seamlessly routes legacy X11 windows (such as Steam or older apps) right inside Niri's layout engine.
* **Desktop Portals (`xdg-desktop-portal-gnome`)**: Essential utility layer that allows internal WebRTC frameworks to handle browser screen-sharing and audio capture.

### Running and Managing the Environment

1. Make the script executable and launch it:
   ```bash
   chmod +x install_niri.sh
   ./install_niri.sh
   ```
2. **Booting up:** If you run a graphical login prompt like **GDM**, select "Niri" from the desktop session gear icon. If you log in via a standard text terminal (TTY), invoke it using the session parsing wrapper:
   ```bash
   niri --session
   ```
3. **Primary Default Keys:** 
   * `Super + T`: Launches **Alacritty Terminal**.
   * `Super + D`: Pulls down **Fuzzel Menu Launcher**.
   * `Super + Shift + E`: Exits the session environment.

If you are using an **NVIDIA graphics card** and need specific kernel environment parameters exported for Wayland stability, or if you want to configure **custom scroll layouts**, let me know!
