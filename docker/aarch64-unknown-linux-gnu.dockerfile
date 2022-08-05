FROM sciolence/cross-rs-custom-aarch64-unknown-linux-gnu:latest

ENV DEBIAN_FRONTEND=noninteractive \
    GSTREAMER_CROSS_SYSROOT="/usr/aarch64-linux-gnu" \
    GSTREAMER_CROSS_SYSTEM="linux" \
    GSTREAMER_CROSS_ARCH="aarch64"

COPY gstreamer.sh /
RUN /gstreamer.sh
