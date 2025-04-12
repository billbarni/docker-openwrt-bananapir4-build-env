#!/bin/bash

rm -rf openwrt
rm -rf mtk-openwrt-feeds

git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
cd openwrt; git checkout 315facfce6dc13d6ec1993db1e16532cadcfcaaa; cd -;	

git clone --branch master https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
#cd mtk-openwrt-feeds; git checkout 612001dcebc0385f0cfe5cc5ccbf5dfd640dd4e1; cd -;
#cd mtk-openwrt-feeds; git checkout d1340b5dd0b879fb66b599c0dbb70b41d4f2d02e; cd -;	#LRO
cd mtk-openwrt-feeds; git checkout 2d24500219727bf7279fdb2d8c06dc2fc74cc5eb; cd -;	#refactor openwrt patches according to SDK rules	

# mtk autobuild rules modification - disable their gerrit
#\cp -r my_files/rules mtk-openwrt-feeds/autobuild/unified

# wireless-regdb modification
rm -rf openwrt/package/firmware/wireless-regdb/patches/*.*
rm -rf mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches/*.*
\cp -r my_files/500-tx_power.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches
\cp -r my_files/regdb.Makefile openwrt/package/firmware/wireless-regdb/Makefile

# jumbo frames support
\cp -r my_files/750-mtk-eth-add-jumbo-frame-support-mt7998.patch openwrt/target/linux/mediatek/patches-6.6

# ethtool upgrade to 6.11
\cp -r my_files/ethtool/Makefile openwrt/package/network/utils/ethtool/Makefile

# tx_power patch
\cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/

# removing iperf issue
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-bpi-r4 log_file=make

#exit 0

# thermal zone addition
\cp -r my_files/w-mt7988a.dtsi openwrt/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7988a.dtsi

cd openwrt

# qmi modems extension
\cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
\cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
\cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
\cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
\cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications

./scripts/feeds update -a
./scripts/feeds install -a

\cp -r ../configs/config.ext-upd-1.0 ./.config

make menuconfig
make -j$(nproc)


