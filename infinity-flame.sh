#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests;
rm -rf out/soong/.intermediates/system/sepolicy;
rm -rf hardware/qcom-caf

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

rm -rf packages/apps/Updater
git clone https://github.com/SiliconxLab/packages_apps_Updater packages/apps/Updater
git clone https://github.com/suchit-7x/vendor_lineage-priv_keys -b infinity vendor/infinity-priv/keys

echo "Setup environment!..."
source build/envsetup.sh

echo "Clone device sources!..."
git clone https://github.com/SiliconxLab/android_device_xiaomi_flame -b build device/xiaomi/flame
git clone https://github.com/SiliconxLab/android_device_xiaomi_flame-kernel device/xiaomi/flame-kernel
git clone https://github.com/SiliconxLab/android_vendor_xiaomi_flame vendor/xiaomi/flame
git clone https://github.com/LineageOS/android_hardware_xiaomi hardware/xiaomi

echo "build started!..."
export BUILD_USERNAME=Suchit
export BUILD_HOSTNAME=foss

lunch infinity_flame-user;
m bacon -j$(nproc --all);

echo "Upload to GoFile will be started..."

wget -q -O upload.sh https://raw.githubusercontent.com/SiliconxLab/scripts/refs/heads/main/upload.sh
chmod +x upload.sh
./upload.sh flame

