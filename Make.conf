#!/bin/bash

# Define the path to make.conf
MAKE_CONF_PATH="/etc/portage/make.conf"

echo "Creating a basic make.conf file at $MAKE_CONF_PATH"

# Create the file (or overwrite if it exists)
cat <<EOF > "$MAKE_CONF_PATH"
# These settings were set by the catalyst build script that automatically
# built this stage.
# Please consult /usr/share/portage/config/make.conf.example for a more
# detailed example.

# Common optimization flags for your CPU architecture.
# Replace 'native' with your specific CPU architecture if desired (e.g., 'skylake', 'amdfam10').
# Consult the GCC manual or info pages for valid -march= settings.
COMMON_FLAGS="-O2 -pipe -march=native"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

# WARNING: Changing your CHOST is not something that should be done lightly.
# Please consult wiki.gentoo.org/wiki/Changing_the_CHOST_variable before changing.
# CHOST="x86_64-pc-linux-gnu" # Example CHOST, usually set during stage3 extraction.

# Global USE flags. These define features enabled/disabled across packages.
# Customize based on your system's needs.
USE="X alsa pulseaudio systemd qt5 gtk3 opengl vulkan networkmanager"

# Portage features.
# parallel-fetch: Download sources in parallel.
# ccache: Cache compiled objects to speed up subsequent builds.
FEATURES="parallel-fetch ccache"

# Number of parallel jobs for compilation.
# Set to the number of CPU cores/threads you want to dedicate to compilation.
MAKEOPTS="-j$(nproc)"

# Acceptable licenses. Adjust based on your comfort level with different licenses.
# "*" accepts all licenses. "-@EULA" excludes End User License Agreements.
ACCEPT_LICENSE="* -@EULA"

# Portage mirrors for faster downloads.
# Uncomment and customize for your region.
# GENTOO_MIRRORS="http://distfiles.gentoo.org/ http://gentoo.osuosl.org/ "

# Input devices for Xorg.
# INPUT_DEVICES="libinput keyboard mouse"

# Video drivers for Xorg.
# VIDEO_CARDS="intel amdgpu nouveau"

# Locale settings.
  # LINGUAS="en_US"
# LC_MESSAGES="C"

# Optional: Set a custom Portage temporary directory if you have a fast temporary storage (e.g., tmpfs).
# PORTAGE_TMPDIR="/run/portage"

EOF

echo "Basic make.conf created. Please review and customize it further based on your system and preferences."
echo "You can find a detailed example at /usr/share/portage/config/make.conf.example"
echo "Remember to run 'emerge --ask --changed-use --deep @world' after making significant USE flag changes."
