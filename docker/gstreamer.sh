#!/usr/bin/env bash

set -x
set -euo pipefail

GSTREAMER_BUILD_DIR="${GSTREAMER_BUILD_DIR:-"/build.gstreamer"}"
GSTREAMER_REPO="${GSTREAMER_REPO:-"https://gitlab.freedesktop.org/gstreamer/gstreamer.git"}"
GSTREAMER_BRANCH="${GSTREAMER_BRANCH:-"1.20"}"

GSTREAMER_CROSS_SYSROOT="${GSTREAMER_CROSS_SYSROOT:-}"
GSTREAMER_CROSS_ARCH="${GSTREAMER_CROSS_ARCH:-}"
GSTREAMER_CROSS_SYSTEM="${GSTREAMER_CROSS_SYSTEM:-}"

setup_dependencies() {
  local PACKAGE_SUFFIX=""
  if [[ "${GSTREAMER_CROSS_ARCH}" == "aarch64" ]]; then
    dpkg --add-architecture arm64
    PACKAGE_SUFFIX=":arm64"
  fi

  apt-get -y update

  apt-get install -y --no-install-recommends \
      python3 \
      python3-pip

  apt-get install -y --no-install-recommends \
      "build-essential" \
      "ca-certificates" \
      "git" \
      "wget" \
      "flex" \
      "bison" \
      "gettext" \
      "gir1.2-freedesktop$PACKAGE_SUFFIX" \
      "gir1.2-glib-2.0$PACKAGE_SUFFIX" \
      "libc6-dev$PACKAGE_SUFFIX" \
      "libavcodec-dev$PACKAGE_SUFFIX" \
      "libavfilter-dev$PACKAGE_SUFFIX" \
      "libcap-dev$PACKAGE_SUFFIX" \
      "libglib2.0-dev$PACKAGE_SUFFIX" \
      "libglib2.0-dev-bin$PACKAGE_SUFFIX" \
      "libgudev-1.0-dev$PACKAGE_SUFFIX" \
      "libjson-glib-dev$PACKAGE_SUFFIX" \
      "libsoup2.4-dev$PACKAGE_SUFFIX" \
      "libv4l-dev$PACKAGE_SUFFIX" \
      "v4l-utils$PACKAGE_SUFFIX" \
      "zlib1g-dev$PACKAGE_SUFFIX"

  pip3 install meson ninja

  apt-get clean
  rm -rf /var/lib/apt/lists/*
}

prepare_crossbuild() {
  if [ -n "${GSTREAMER_CROSS_ARCH}" ]; then
    touch "/build-gstreamer-cross-file.txt"
    cat <<EOF >> /build-gstreamer-cross-file.txt
[host_machine]
system = '$GSTREAMER_CROSS_SYSTEM'
cpu_family = '$GSTREAMER_CROSS_ARCH'
cpu = '$GSTREAMER_CROSS_ARCH'
endian = 'little'

[binaries]
c = '$GSTREAMER_CROSS_ARCH-linux-gnu-gcc'
cpp = '$GSTREAMER_CROSS_ARCH-linux-gnu-g++'
ar = '$GSTREAMER_CROSS_ARCH-linux-gnu-ar'
strip = '$GSTREAMER_CROSS_ARCH-linux-gnu-strip'
pkgconfig = 'pkg-config'
EOF
  fi
}

make_gstreamer() {
  mkdir -p "$GSTREAMER_BUILD_DIR"
  git clone --depth 1 -b "$GSTREAMER_BRANCH" "$GSTREAMER_REPO" "$GSTREAMER_BUILD_DIR"
  cd $GSTREAMER_BUILD_DIR

  MESON_OPTIONS="-Dpython=disabled -Dlibav=disabled -Dlibnice=disabled -Dugly=disabled -Dbad=enabled -Ddevtools=disabled -Dges=disabled -Drtsp_server=disabled -Dgst-examples=disabled -Dqt5=disabled -Dtests=disabled -Dexamples=disabled -Ddoc=disabled -Dgtk_doc=disabled"

  MESON_CROSS_OPTIONS=""
  if [ -n "${GSTREAMER_CROSS_ARCH}" ]; then
    MESON_CROSS_OPTIONS="--cross-file /build-gstreamer-cross-file.txt"
  fi

  meson build $MESON_CROSS_OPTIONS -Dprefix=/usr $MESON_OPTIONS
  ninja -C build
  ninja -C build install
  # DESTDIR=/gstreamer ninja -C build install
}

main() {
  setup_dependencies
  prepare_crossbuild
  make_gstreamer
}

main "${@}"
