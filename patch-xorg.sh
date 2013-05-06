#!/bin/bash

# This tiny script automates patching, building, installation, 
# and setting on hold xorg-server-core package for fixing
# infamous bug #865 preventing usage of keyboard shortcuts
# including other one (e.g. Alt+Shift for layout switching).

set -e

if [[ $(id -u) != 0 ]]; then
    echo "Should be run as root" >&2
    exit 1
fi

echo "Installing nessessary packages..."
apt-get -y install devscripts
apt-get -y build-dep xorg-server
apt-get -y source xorg-server

echo "Downloading patch..."
# see all patches at https://bugs.freedesktop.org/show_bug.cgi?id=865
curl -o xorg.patch "https://bugs.freedesktop.org/attachment.cgi?id=63378"

echo "Applying patch..."
src_root=$(ls -d xorg-server-*)
# backup will be made just in case
patch -p1 -d "$src_root" -b < xorg.patch

echo "Building xorg..."
cd "$src_root"
debuild -us -uc > ../build.log
cd ..

echo "Intstalling xorg..."
dpkg -i xserver-xorg-core_*.deb

echo "Setting hold..."
dpkg --set-selections <<< "xserver-xorg-core hold"

echo "Congratulations!"
