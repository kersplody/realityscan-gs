# Dockerfile: ubuntu-firefox (robust download + x11-apps + bzip2/xz support)
FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/kersplody/realityscan-gs"
LABEL org.opencontainers.image.licenses="Commercial"

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV DISPLAY=:99
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
ENV RS_REST_PORT=8080
ENV RS_GRPC_PORT=50051

# Install required packages (curl/wget, bzip2/xz support, x11-apps and GTK deps)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget ca-certificates xvfb \
        libx11-6 libxcb1 libxext6 libxrender1 libgl1-mesa-glx \
        libvulkan1 vulkan-tools mesa-vulkan-drivers \
        libgtk-3-0 libglib2.0-0 \
        libnss3 libasound2 libdrm2 libgbm1 libgl1 libglapi-mesa \
        libatk1.0-0 libatk-bridge2.0-0 libcups2 libxkbcommon0 \
        winbind libfontconfig1 libsensors5 \
    && rm -rf /var/lib/apt/lists/*

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

RUN mkdir /tmp/runtime-root && chmod 700 /tmp/runtime-root

EXPOSE 8080 50051

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["server"]
