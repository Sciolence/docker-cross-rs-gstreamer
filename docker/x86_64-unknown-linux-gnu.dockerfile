FROM ghcr.io/cross-rs/x86_64-unknown-linux-gnu:main

ENV DEBIAN_FRONTEND=noninteractive

COPY gstreamer.sh /
RUN /gstreamer.sh
