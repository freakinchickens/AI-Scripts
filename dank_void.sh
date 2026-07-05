# Install Necessary Programs
sudo xbps-install -Sy git base-devel cargo nodejs \
    qt6-declarative-devel qt6-wayland-devel qt6-svg-devel \
    niri pipewire wireplumber wayland-utils wl-clipboard \
    greetd pam-devel acl libseat-devel

# Clone and build Quickshell
git clone --recursive https://github.com
cd quickshell
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target all
sudo cmake --install build
cd ..

# Install Matugen (required for DMS themes)
cargo install matugen
sudo cp ~/.cargo/bin/matugen /usr/local/bin/

# Clone the repository
git clone https://github.com
cd DankMaterialShell

# Build the core components
make build

# Install the binary manually to your local bin path
sudo cp bin/dms /usr/local/bin/

# Generate starter configs for your user profile
dms setup

# Clone the repository
git clone https://github.com
cd DankMaterialShell

# Build the core components
make build

# Install the binary manually to your local bin path
sudo cp bin/dms /usr/local/bin/

# Generate starter configs for your user profile
dms setup

exec-once = dms 

dms greeter sync
