#!/usr/bin/env bash
set -e

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root (sudo)."
  exit 1
fi

echo "=== 1. Selecting a Desktop Profile ==="
# Find and select the generic desktop profile (non-systemd / openrc baseline)
# Change to a systemd profile if your Gentoo installation uses systemd
DESKTOP_PROFILE=$(eselect profile list | grep "desktop (stable)" | head -n 1 | awk -F'[][]' '{print $2}' | tr -d ' ')
if [ -n "$DESKTOP_PROFILE" ]; then
    eselect profile set "$DESKTOP_PROFILE"
    echo "Profile set to desktop."
else
    echo "Warning: Could not automatically detect standard desktop profile. Skipping profile switch."
fi

echo "=== 2. Configuring Global USE Flags ==="
# Append necessary desktop and Xfce flags to make.conf
MAKE_CONF="/etc/portage/make.conf"
mkdir -p /etc/portage/package.use

# Ensure critical GUI flags are set globally
for flag in xorg xfce gtk gtk3 dbus elofind udev alsa pulseaudio connection-sharing; do
    if ! grep -q "USE=.*$flag" "$MAKE_CONF"; then
        echo "Appending global USE flag: $flag"
        # If no USE line exists, create one; otherwise append to it safely
        if grep -q "^USE=" "$MAKE_CONF"; then
            sed -i "/^USE=/s/\"$/ $flag\"/" "$MAKE_CONF"
        else
            echo "USE=\"$flag\"" >> "$MAKE_CONF"
        fi
    fi
done

echo "=== 3. Customizing Package-Specific USE Flags ==="
# Configure the xfce4-meta bundle package options
cat << 'EOF' > /etc/portage/package.use/xfce
xfce-base/xfce4-meta svg archive calendar editor image media pulseaudio
x11-base/xorg-server -minimal
EOF

echo "=== 4. Syncing and Updating @world Set ==="
emaint sync -r gentoo
echo "Updating world to register new profile and USE definitions..."
emerge --update --deep --newuse --ask=n @world

echo "=== 5. Installing Xorg Server and Display Drivers ==="
emerge --ask=n x11-base/xorg-server

echo "=== 6. Installing Xfce Meta Package and Companion Tools ==="
# Installs core desktop environment along with system manager wrappers
emerge --ask=n xfce-base/xfce4-meta \
               x11-terms/xfce4-terminal \
               xfce-extra/xfce4-notifyd \
               xfce-extra/xfce4-pulseaudio-plugin \
               x11-misc/lightdm \
               x11-misc/lightdm-gtk-greeter \
               net-misc/networkmanager

echo "=== 7. Updating Environment Variables ==="
env-update && source /etc/profile

echo "=== 8. Configuring Services and User Permissions ==="
# Enable essential system runlevel scripts (OpenRC default assumed)
if command -v rc-update >/dev/null 2>&1; then
    rc-update add dbus default || true
    rc-update add elogind default || true
    rc-update add NetworkManager default || true
    rc-update add xdm default || true
    
    # Configure LightDM as the primary graphical login provider
    sed -i 's/CHECK_KEYMAP=.*/CHECK_KEYMAP="no"/' /etc/conf.d/xdm
    sed -i 's/DISPLAYMANAGER=.*/DISPLAYMANAGER="lightdm"/' /etc/conf.d/xdm
fi

# Automatically add active standard user accounts to relevant local media hardware groups
for username in $(awk -F: '$3 >= 1000 && $3 < 60000 {print $1}' /etc/passwd); do
    echo "Adding user ${username} to desktop groups..."
    for group in video audio cdrom cdrw usb input wheel; do
        getent group "$group" >/dev/null && gpasswd -a "$username" "$group" || true
    done
done

echo "=== 9. Creating Standard Fallback .xinitrc ==="
# Sets up fallback for users starting desktop via startx TTY command line tool
for user_dir in /home/*; do
    if [ -d "$user_dir" ]; then
        XINIT="$user_dir/.xinitrc"
        echo "exec startxfce4" > "$XINIT"
        chown $(basename "$user_dir"): "$XINIT"
        chmod +x "$XINIT"
    fi
done

echo "=== SUCCESS: Xfce compilation and installation finished! ==="
echo "Reboot system to initiate the LightDM graphical login menu panel."
