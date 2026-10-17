#!/bin/bash

echo "removing local manifests"
rm -rf .repo/local_manifests;
rm -rf out/soong/.intermediates/system/sepolicy;
rm -rf hardware/qcom-caf

echo "Initialize EvolutionX manifest"
repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs --depth=1

echo "Sync EvolutionX Source"
/opt/crave/resync.sh;

sudo apt-get update && sudo apt-get install patchelf coreutils -y;

rm -rf build/soong/fsgen;

echo "Clone device specific changes"
rm -rf hardware/qcom-caf/common
git clone https://github.com/spring4ever/android_hardware_qcom-caf_common hardware/qcom-caf/common
git clone https://github.com/spring4ever/android_vendor_qcom_opensource_agm hardware/qcom-caf/sm6375-6.1/audio/agm
git clone https://github.com/spring4ever/android_vendor_qcom_opensource_arpal-lx hardware/qcom-caf/sm6375-6.1/audio/pal
git clone https://github.com/spring4ever/android_hardware_qcom_audio-ar hardware/qcom-caf/sm6375-6.1/audio/primary-hal
git clone https://github.com/spring4ever/android_vendor_qcom_opensource_audioreach-graphservices hardware/qcom-caf/sm6375-6.1/audio/graphservices
git clone https://github.com/spring4ever/android_hardware_qcom_display hardware/qcom-caf/sm6375-6.1/display
git clone https://github.com/spring4ever/android_vendor_qcom_opensource_dataipa hardware/qcom-caf/sm6375-6.1/dataipa
git clone https://github.com/spring4ever/android_vendor_qcom_opensource_data-ipa-cfg-mgr hardware/qcom-caf/sm6375-6.1/data-ipa-cfg-mgr
ln -sf ../common/os_pickup_qssi.bp hardware/qcom-caf/sm6375-6.1/Android.bp
git clone https://github.com/suchit-7x/vendor_lineage-priv_keys -b evolution vendor/evolution-priv/keys

git clone https://github.com/swiitch-OFF-Lab/hardware_dolby -b sony-A17 hardware/dolby
git clone https://github.com/swiitch-OFF-Lab/packages_apps_DolbyUI -b 16.0 packages/apps/DolbyUI

echo "Setup environment!..."
source build/envsetup.sh

echo "Clone device sources!..."
git clone https://github.com/SiliconxLab/android_device_xiaomi_spring -b evolution device/xiaomi/spring
git clone https://github.com/spring4ever/android_device_xiaomi_spring-kernel device/xiaomi/spring-kernel
git clone https://github.com/spring4ever/android_vendor_xiaomi_spring vendor/xiaomi/spring
git clone https://github.com/LineageOS/android_hardware_xiaomi hardware/xiaomi

echo "build started!..."
export BUILD_USERNAME=Suchit
export BUILD_HOSTNAME=foss

lunch lineage_spring-cp2a-user;
m evolution -j$(nproc --all);

echo "Upload to GoFile will be started..."

ZIP=$(find out/target/product/spring -maxdepth 1 -type f -name "*.zip" | head -n 1)

if [ -n "$ZIP" ]; then
    echo "Uploading $ZIP..."
    wget https://raw.githubusercontent.com/lordgaruda/GoFile-Upload/refs/heads/master/upload.sh
    chmod +x upload.sh
    ./upload.sh "$ZIP"
else
    echo "No ROM ZIP found!"
    exit 1
fi
