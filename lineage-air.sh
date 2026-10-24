#!/bin/bash

echo "========================"
echo "removing local manifests"
echo "========================"

rm -rf .repo/local_manifests
rm -rf out/soong/.intermediates/system/sepolicy

echo "====================="
echo "      Repo init      "
echo "====================="

repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs --depth=1

echo "==================="
echo "     repo sync     "
echo "==================="

/opt/crave/resync.sh

sudo apt-get update && sudo apt-get install patchelf coreutils -y

rm -rf build/soong/fsgen

git clone https://github.com/suchit-7x/vendor_lineage-priv_keys -b lineage vendor/lineage-priv/keys

echo "Setup environment!..."
source build/envsetup.sh

echo "Clone device sources!..."
git clone https://github.com/mt6835-devs/android_device_xiaomi_air device/xiaomi/air
git clone https://github.com/mt6835-devs/android_device_xiaomi_air-kernel device/xiaomi/air-kernel

rm air_in_global-ota_full-OS2.0.208.0.VGQINXM-user-15.0-93391672cc.zip
wget https://bkt-sgp-miui-ota-update-alisgp.oss-ap-southeast-1.aliyuncs.com/OS2.0.208.0.VGQINXM/air_in_global-ota_full-OS2.0.208.0.VGQINXM-user-15.0-93391672cc.zip
cd device/xiaomi/air
chmod +x extract-files.py
./extract-files.py ../../../air_in_global-ota_full-OS2.0.208.0.VGQINXM-user-15.0-93391672cc.zip
cd -

git clone https://github.com/mt6835-devs/android_hardware_xiaomi hardware/xiaomi
git clone https://github.com/mt6835-devs/android_hardware_mediatek hardware/mediatek
git clone https://github.com/mt6835-devs/android_vendor_mediatek_ims vendor/mediatek/ims
git clone https://github.com/mt6835-devs/android_device_mediatek_sepolicy_vndr device/mediatek/sepolicy_vndr

echo "build started!..."
export BUILD_USERNAME=Suchit
export BUILD_HOSTNAME=foss

lunch lineage_air-bp4a-eng
m bacon -j$(nproc --all)

echo "Upload to GoFile will be started..."

wget -q -O upload.sh https://raw.githubusercontent.com/SiliconxLab/scripts/refs/heads/main/upload.sh
chmod +x upload.sh
./upload.sh air

