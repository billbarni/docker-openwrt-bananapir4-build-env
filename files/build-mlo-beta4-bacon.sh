#!/bin/bash

rm -rf openwrt
rm -rf mtk-openwrt-feeds

git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt; git checkout 56559278b78900f6cae5fda6b8d1bb9cda41e8bf; cd -;	#hostapd: add missing #ifdef to fix compile error when 802.11be support is disabled

git clone --branch master https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
cd mtk-openwrt-feeds; git checkout 6356091a0f7dd3d02afadaa9b604aa8d74267018; cd -;	#Fix ETH driver bring up issue when eth2 SFP is enabled

# wireless-regdb modification
#rm -rf /home/user/openwrt/package/firmware/wireless-regdb/patches/*.*
#rm -rf /home/user/mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches/*.*
#\cp -r /home/user/files/my_files/500-tx_power.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches
#\cp -r /home/user/files/my_files/regdb.Makefile openwrt/package/firmware/wireless-regdb/Makefile

# jumbo frames support
#\cp -r /home/user/files/my_files/750-mtk-eth-add-jumbo-frame-support-mt7998.patch openwrt/target/linux/mediatek/patches-6.6

# tx_power patch
\cp -r /home/user/files/my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/

# removing iperf issue
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

cd openwrt
bash /home/user/mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-bpi-r4 log_file=make

# thermal zone addition
\cp -r /home/user/files/my_files/wozi-mt7988a.dtsi openwrt/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7988a.dtsi

cd openwrt

# qmi modems extension
\cp -r /home/user/files/my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
\cp -r /home/user/files/my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
\cp -r /home/user/files/my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
\cp -r /home/user/files/my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
\cp -r /home/user/files/my_files/luci-app-at-socat/ feeds/luci/applications

# fibocom ncm
#\cp -r /home/user/files/my_files/atc-fib-fm350_gl feeds/packages/net/atc-fib-fm350_gl
#\cp -r /home/user/files/my_files/luci-proto-atc feeds/luci/protocols

./scripts/feeds update -a
./scripts/feeds install -a

\cp -r /home/user/files/configs/config.beta4.ext .config

make menuconfig
make -j$(nproc)
