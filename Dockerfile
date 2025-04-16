FROM alpine:latest AS clone_stage
################################################################
# CLONE STAGE
################################################################

# Install git and any other tools you might need, like bash
RUN apk update && apk add --no-cache git bash

# Copy local config files and patches
COPY configs configs
COPY my_files my_files
COPY bpi-r4-openwrt-builder_1.sh bpi-r4-openwrt-builder_1.sh
COPY bpi-r4-openwrt-builder_2.sh bpi-r4-openwrt-builder_2.sh

# Clone the OpenWrt repository
RUN git clone --branch openwrt-24.10 https://git.openwrt.org/openwrt/openwrt.git openwrt || true
RUN cd openwrt; git checkout a51b1a98e026887ea4dd8f09a6fdc8138941e2ac; cd -;

# Clone the Mediatek OpenWrt feeds repository
RUN git clone --branch master https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
RUN cd mtk-openwrt-feeds; git checkout d97c445b5a0a6848686d1811003f84ffb5d3d1bf; cd -;

RUN echo "d97c445" > mtk-openwrt-feeds/autobuild/unified/feed_revision

RUN cd openwrt
RUN echo "src-git mtk_openwrt_feed https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds" >> feeds.conf.default

FROM debian:latest AS config_stage
################################################################
# CONFIG STAGE
################################################################

# Update package list, upgrade packages, and install dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y build-essential clang flex bison g++ gawk \
    gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
    python3-setuptools rsync swig unzip zlib1g-dev file wget && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user called "builder" and set up its home directory.
# The flag -m creates the home directory automatically.
RUN useradd -m builder

# Copy necessary files from clone_stage
COPY --from=clone_stage configs configs
COPY --from=clone_stage my_files my_files
COPY --from=clone_stage bpi-r4-openwrt-builder_1.sh bpi-r4-openwrt-builder_1.sh
COPY --from=clone_stage bpi-r4-openwrt-builder_2.sh bpi-r4-openwrt-builder_2.sh
COPY --from=clone_stage openwrt openwrt
COPY --from=clone_stage mtk-openwrt-feeds mtk-openwrt-feeds

# Change ownership of the files and directories so that the new user can access and modify them.
# Adjust the directories/files below if your build requires other paths.
RUN chown -R builder:builder configs my_files bpi-r4-openwrt-builder_1.sh \
    bpi-r4-openwrt-builder_2.sh openwrt mtk-openwrt-feeds

# Switch to the non-root user and set the working directory within their home folder.
USER builder
WORKDIR /home/builder

# Run the builder scripts as the non-root user.
RUN bash bpi-r4-openwrt-builder_1.sh
RUN bash bpi-r4-openwrt-builder_2.sh

# Copy the final output (if needed)
RUN cp -r openwrt/bin/ output