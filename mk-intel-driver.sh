#!/usr/bin/env bash

# Initial script
echo "$(date "+%d.%m.%Y %T") INFO: *** Initializing Script ***"
cd "$HOME/"
echo "$(date "+%d.%m.%Y %T") INFO: *** Creating master directory. ***"
mkdir intel-driver
sleep 5
cd "$HOME/intel-driver"
echo "$(date "+%d.%m.%Y %T") INFO: *** Installing prerequisites needed to build the iHD driver. ***"
sudo apt-get install -y software-properties-common vainfo autoconf libtool libdrm-dev xorg xorg-dev openbox libx11-dev libgl1-mesa-glx libgl1-mesa-dev xutils-dev build-essential cmake
echo "$(date "+%d.%m.%Y %T") INFO: *** Cloning libva git. ***"
git clone "https://github.com/intel/libva.git"
sleep 5
cd "$HOME/intel-driver/libva"
echo "$(date "+%d.%m.%Y %T") INFO: *** Building and installing libva (VAAPI). ***"
./autogen.sh --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu
sleep 5
make
sleep 5
sudo make install
sleep 5

# Building media driver
cd $HOME/intel-driver
echo "$(date "+%d.%m.%Y %T") INFO: *** Cloning media-driver and gmmlib gits. ***"
git clone https://github.com/intel/media-driver.git
sleep 5
git clone https://github.com/intel/gmmlib.git
sleep 5
mkdir build_media
sleep 5
cd "$HOME/intel-driver/build_media"
echo "$(date "+%d.%m.%Y %T") INFO: *** Building media-driver. ***"
cmake -DCMAKE_INSTALL_PREFIX=/usr ../media-driver
sleep 5
make -j8

# Removing and copying new driver.
echo "$(date "+%d.%m.%Y %T") INFO: *** Removing old iHD driver. ***"
sudo rm -rf "/usr/lib/x86_64-linux-gnu/dri/iHD_drv_video.so"
sudo cp "$HOME/intel-driver/build_media/media_driver/iHD_drv_video.so" "/usr/lib/x86_64-linux-gnu/dri/"
export "LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri/"
export "LIBVA_DRIVER_NAME=iHD"
echo "$(date "+%d.%m.%Y %T") INFO: *** Script is now complete. ***"

echo "$(date "+%d.%m.%Y %T") INFO: *** Running vainfo to verify script worked. ***"
vainfo
