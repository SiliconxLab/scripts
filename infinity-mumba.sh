#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests;
rm -rf out/soong/.intermediates/system/sepolicy;

echo "====================="
echo "      Repo init      "
echo "====================="

repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 17 -g default,-mips,-darwin,-notdefault;

echo "==================="
echo "     repo sync     "
echo "==================="

/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;

rm -rf build/soong/fsgen;

echo "Setup environment!..."
source build/envsetup.sh

echo "Clone device sources!..."
git clone https://github.com/SiliconxLab/android_device_motorola_mumba device/motorola/mumba
git clone https://github.com/moto-elysia/android_device_motorola_mumba-kernel.git device/motorola/mumba-kernel
git clone https://github.com/moto-elysia/android_vendor_motorola_mumba.git vendor/motorola/mumba
git clone https://github.com/moto-elysia/android_hardware_motorola.git hardware/motorola

echo "build started!..."
export BUILD_USERNAME=Suchit
export BUILD_HOSTNAME=foss

lunch infinity_mumba-user;
m bacon -j$(nproc --all);

echo "Upload to GoFile will be started..."

ZIP=$(find out/target/product/mumba -maxdepth 1 -type f -name "*.zip" | head -n 1)

if [ -n "$ZIP" ]; then
    echo "Uploading $ZIP..."
    wget https://raw.githubusercontent.com/lordgaruda/GoFile-Upload/refs/heads/master/upload.sh
    chmod +x upload.sh
    ./upload.sh "$ZIP"
else
    echo "No ROM ZIP found!"
    exit 1
fi
