FROM sciolence/cross-rs-custom-x86_64-unknown-linux-gnu:latest

ENV DEBIAN_FRONTEND=noninteractive

COPY gstreamer.sh /
RUN /gstreamer.sh
