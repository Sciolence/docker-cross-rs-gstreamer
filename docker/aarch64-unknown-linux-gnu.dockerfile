FROM ghcr.io/cross-rs/aarch64-unknown-linux-gnu:main

ENV DEBIAN_FRONTEND=noninteractive \
    GSTREAMER_CROSS_SYSROOT="/usr/aarch64-linux-gnu" \
    GSTREAMER_CROSS_SYSTEM="linux" \
    GSTREAMER_CROSS_ARCH="aarch64"

COPY gstreamer.sh /
RUN /gstreamer.sh
