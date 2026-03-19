# Dockerfile: ubuntu-firefox (robust download + x11-apps + bzip2/xz support)
FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/kersplody/realityscan-gs"
LABEL org.opencontainers.image.licenses="Commercial"

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages (curl/wget, bzip2/xz support, x11-apps and GTK deps)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      curl wget bzip2 xz-utils x11-apps ca-certificates \
      libgtk-3-0 libdbus-glib-1-2 libxt6 \
      libx11-xcb1 libxcb-shm0 libxcb-dri3-0 \
      libvulkan1 vulkan-tools \
      libxcomposite1 libasound2 && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt

#download from EPIC, move to external
#https://www.unrealengine.com/en-US/realityscan/linux
COPY external/RealityScan-2.1.deb /opt/RealityScan-2.1.deb
#Copy from a windows install of RealityScan 2.1 into external
# $install_path\RealityScan_2.1\Plugins\RealityScan.RemoteCommandPlugin
# e.g. E:\epic\RealityScan_2.1\Plugins\RealityScan.RemoteCommandPlugin
COPY external/RealityScan.RemoteCommandPlugin.rsplugin /opt/RealityScan.RemoteCommandPlugin.rsplugin
COPY external/RealityScan.RemoteCommandPlugin.dll /opt/RealityScan.RemoteCommandPlugin.dll

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends /opt/RealityScan-2.1.deb && \
    rm -rf /var/lib/apt/lists/* && \
    rm /opt/RealityScan-2.1.deb

ENV RS_EXE="/opt/realityscan/support/realityscan/drive_c/Program Files/Epic Games/RealityScan/RealityScan.exe" \
    RS_ARGS="-registerPlugin /opt/RealityScan.RemoteCommandPlugin.rsplugin" \
    CON_NAME="F2BF1A58-867E-4DB1-A524-9D8291BCE69D" \
    RSREMOTE_ARGS="-RsRemoteStartREST http://0.0.0.0:4321"

COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
# CMD ["bash"]
