#!/bin/bash

cd openwrt
# Basic config for bpi-r4
\cp -r ../configs/bpi-r4_basic_config .config

#Basic config for bpi-r4 poe
#\cp -r ../configs/bpi-r4-poe_basic_config .config

###### Then you can add all required additional feeds/packages ######### 

# qmi modems extension for example
\cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
\cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
\cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
\cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
\cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications

export FORCE_UNSAFE_CONFIGURE=1

./scripts/feeds update -a
./scripts/feeds install -a

####### And finally configure whatever you want ##########

#make menuconfig
make V=s PKG_HASH=skip PKG_MIRROR_HASH=skip
