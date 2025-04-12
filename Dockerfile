FROM alpine:latest AS clone_stage
################################################################ CLONE STAGE
################################################################

# Install git and any other tools you might need, like bash
RUN apk update && apk add --no-cache git bash

# Set the working directory
WORKDIR /home

# Copy local config files and patches
COPY files files/

# Clone the OpenWrt repository
RUN git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
RUN cd openwrt; git checkout 56559278b78900f6cae5fda6b8d1bb9cda41e8bf; cd -;	

# Clone the Mediatek OpenWrt feeds repository
RUN git clone --branch master https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
RUN cd mtk-openwrt-feeds; git checkout 6356091a0f7dd3d02afadaa9b604aa8d74267018; cd -;

RUN cd openwrt
RUN echo "src-git mtk_openwrt_feed https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds" >> feeds.conf.default

FROM ubuntu:24.04 AS build_stage
################################################################ BUILD STAGE
################################################################

# Disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install dependencies
RUN apt-get update && \
  apt-get install -y \
  build-essential \
  git \
  libncurses5-dev \
  libssl-dev \
  zlib1g-dev \
  gawk \
  subversion \
  mercurial \
  wget \
  unzip \
  file \
  rsync \
  && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /home

# Copy necessary files from clone_stage. hopefully to allow chaching?
COPY --from=clone_stage /home/files files
COPY --from=clone_stage /home/openwrt openwrt
COPY --from=clone_stage /home/mtk-openwrt-feeds mtk-openwrt-feeds

# Update and install all feeds
RUN openwrt/scripts/feeds update -a && openwrt/scripts/feeds install -a

# copy tx_power patch from 'files' to 'mtk-openwrt-feeds'
RUN \cp -r files/my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/

# removing iperf issue
RUN sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
RUN sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
RUN sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

# thermal zone addition
RUN \cp -r files/my_files/wozi-mt7988a.dtsi openwrt/target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mt7988a.dtsi

RUN \cp -af mtk-openwrt-feeds/master/files/* openwrt
RUN \cp -rf mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/* openwrt

# qmi modems extension
#RUN \cp -r files/my_files/luci-app-3ginfo-lite-main/sms-tool/ openwrt/feed/packages/utils/sms-tool
#RUN \cp -r files/my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ openwrt/feed/luci/applications
#RUN \cp -r files/my_files/luci-app-modemband-main/luci-app-modemband/ openwrt/feed/luci/applications
#RUN \cp -r files/my_files/luci-app-modemband-main/modemband/ openwrt/feed/packages/net/modemband
#RUN \cp -r files/my_files/luci-app-at-socat/ openwrt/feed/luci/applications

# If you have a pre-made configuration file, copy it into the container.
# Place your ".config" file in the same directory as the Dockerfile.
# If you do not have one, the build process will generate defaults.
RUN \cp files/configs/config.beta4.ext openwrt/.config

# Change to the 'openwrt' directory and apply each patch found in /mtk-openwrt-feeds/master/patches-base
RUN cd openwrt && \
   for file in $(find /home/mtk-openwrt-feeds/master/patches-base -name "*.patch" | sort); do \
       echo "Applying patch: $file"; \
       patch -f -p1 -i "$file"; \
   done

# (Optional) Run the default configuration to ensure consistency
RUN cd openwrt; bash lede-build-sanity.sh; cd -;

# Start the build process using all available CPU cores.
# Adjust '-j$(nproc)' based on your system’s available cores.
RUN cd openwrt; make V=s PKG_HASH=skip PKG_MIRROR_HASH=skip -j$(nproc); cd -;
#RUN make -j$(nproc)

# Optionally expose a volume so you can retrieve the build artifacts later.
# The compiled firmware will usually be found in the "bin" directory.