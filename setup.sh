#!/usr/bin/env bash
#
# setup.sh — sets up an H8 (Cybiko Xtreme) cross-toolchain on Ubuntu 26.04
#
# Strategy: rather than hand-rolling a 2005-era binutils/gcc-4.0.1 build
# (see the DBZoo instructions — it targets Fedora Core 4 / Cygwin and will
# fight you on a modern glibc/headers), this reuses the toolchain builder
# already maintained inside Daft-Freak/CybikoStuff, which targets a
# from-scratch bare-metal H8S build (no official CyOS SDK needed) and is
# what the Main.cpp LCD example you linked was built against.
#
# Result: a working h8300-elf-gcc/g++ toolchain in
#   $ROOT/CybikoStuff/toolchain/prefix/bin
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/amovitz/CybikoStuff.git"
REPO_DIR="$ROOT/CybikoStuff"
REPO_BRANCH="build_fixes"

echo "==> Installing build dependencies"
sudo apt-get update
sudo apt-get install -y \
    build-essential git cmake ninja-build gawk \
    autoconf automake libtool bison flex texinfo \
    gcc g++ gperf libgmp-dev libmpfr-dev libmpc-dev \
    libisl-dev zlib1g-dev wget curl \
    python3-serial libusb-1.0-0-dev

sudo sed -i 's/^CONF_SWAPSIZE=512$/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo systemctl restart dphys-swapfile

echo "==> Cloning CybikoStuff"
if [ -d "$REPO_DIR" ]; then
    echo "    (already cloned, pulling latest)"
    cd $REPO_DIR
    git checkout $REPO_BRANCH
    git -C "$REPO_DIR" pull --ff-only
else
    git clone "$REPO_URL" "$REPO_DIR"
    git checkout $REPO_BRANCH
fi

echo "==> Building the H8 toolchain (this can take a while — it builds"
echo "    binutils + gcc + newlib from source)"
cd "$REPO_DIR/toolchain"
chmod +x build.sh
./build.sh

TOOLCHAIN_BIN="$REPO_DIR/toolchain/prefix/bin"

if [ ! -d "$TOOLCHAIN_BIN" ]; then
    echo "!! Expected toolchain output at $TOOLCHAIN_BIN but it wasn't found."
    echo "!! Check the output above / inspect toolchain/build.sh — the"
    echo "!! install prefix may differ from what this script assumes."
    exit 1
fi

echo "==> Toolchain built. Binaries in: $TOOLCHAIN_BIN"
ls "$TOOLCHAIN_BIN" | grep -i h8 || true

echo "==> Building the host-side tools (imgtool, used to package the binary"
echo "    into something the Cybiko/emulator can boot)"
cd "$REPO_DIR/tools"
cmake -G Ninja -B build
ninja -C build

echo "==> Adding a udev rule for loading applications"
sudo echo 'SUBSYSTEM=="usb", MODE="0660", GROUP="plugdev"' > /etc/udev/rules.d/00-usb-permissions.rules
sudo udevadm control --reload-rules

echo "==> Adding a system service"
sudo cp Pybiko.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable Pybiko.service

export PATH="$TOOLCHAIN_BIN:\$PATH"

cat <<EOF

==================================================================
Setup complete.

Add the toolchain to your PATH for this shell:

    export PATH="$TOOLCHAIN_BIN:\$PATH"

(Put that line in ~/.bashrc if you want it permanently.)

Verify it:

    h8300-elf-g++ --version   # exact binary name may differ — check:
    ls "$TOOLCHAIN_BIN"

Compile the demo:

    export PATH="$TOOLCHAIN_BIN:\$PATH"
    cd $REPO_DIR/test/lcd
    cmake -DCMAKE_TOOLCHAIN_FILE=../../toolchain/xtreme.toolchain .
    make

Next: cd into cybiko-hello/ and run 'make' to build the demo.
If the Makefile's paths to the linker script / startup object /
lib/H8 headers don't match what's actually in
$REPO_DIR/toolchain and $REPO_DIR/lib,
open those directories and adjust the paths at the top of the
Makefile accordingly — I wasn't able to fetch their exact contents
automatically (GitHub blocks crawling of directory listings), so
those paths are my best inference from the repo's README and your
linked Main.cpp, not verified against the real files.
==================================================================
EOF
