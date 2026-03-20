# RealityScan 2.1 Docker Build

This repository contains a Docker build for running RealityScan 2.1 as a daemon.

## Required Files

The `Dockerfile` expects these exact files and locations:

- `external/RealityScan-2.1.deb`
- `external/RealityScan.RemoteCommandPlugin.rsplugin`
- `external/RealityScan.RemoteCommandPlugin.dll`

RealityScan-2.1.deb can be downloaded from https://www.unrealengine.com/en-US/realityscan/linux (Epic developer login required)

RealityScan.RemoteCommandPlugin.rsplugin and RealityScan.RemoteCommandPlugin.dll are sourced from a Windows install of RealityScan in the Plugins directory. Something like `E:\epic\RealityScan_2.1\Plugins\RealityScan.RemoteCommandPlugin`

## Build

Run:

```bash
docker build -t realityscan:2.1 .
```

## Run

WSL2+Docker:
No hardware acceleration is present due to missing NVIDIA vulkan bindings.
```
docker run -d --gpus all -p 8080:8080
  -v /usr/lib/wsl/lib:/usr/lib/wsl/lib:ro \
  -e LD_LIBRARY_PATH=/usr/lib/wsl/lib:${LD_LIBRARY_PATH} \
  -v /workspace:/workspace
  -e NVIDIA_DRIVER_CAPABILITIES=all --rm -d
  realityscan:2.1 server
```
Linux:
```
docker run --rm -d --gpus all \
  -p 8080:8080 \
  -v /etc/vulkan/icd.d:/etc/vulkan/icd.d:ro \
  -v /usr/share/vulkan/icd.d:/usr/share/vulkan/icd.d:ro \
  -v /dev/dri:/dev/dri \
  -v /workspace:/workspace \
  -v /usr/lib/x86_64-linux-gnu/libGLX_nvidia.so.0:/usr/lib/x86_64-linux-gnu/libGLX_nvidia.so.0:ro \
  -v /usr/lib/x86_64-linux-gnu/libEGL_nvidia.so.0:/usr/lib/x86_64-linux-gnu/libEGL_nvidia.so.0:ro \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  realityscan:2.1 server
```

## API

http://localhost:8080/status will return something like:
```
{
    "processId":-1,
    "progress":0.000000,
    "timeTotal":1346.551911,
    "timeEstimation":0.000000,

    "isSequencerEmpty":true,
    "isMasterBusy":false,
    "isBackgroundBusy":false,
    "changeCounter":0,

    "errorCode":0,
    "errorMessage":""
}
```

RealityScan is a Windows application and wants UNC paths. Mounts are relative to Z:\

```
curl -v -X POST "http://localhost:8080/cmds" \
  -H 'Content-Type: text/plain' \
  --data-binary '-newScene -addFolder Z:\workspace\path\to\images -align -selectMaximalComponent -exportRegistration Z:\workspace\export Z:\workspace\etc\rs_colmap_export.xml -save Z:\workspace\rs.rsproj --newScene'
```

If successful, we will get a 202 Accepted. You can then check /status for updates. It can take a few minutes for any progress to show, but isMasterBusy should report 'true' until the command is complete.

In during processing:
```
{
    "processId":4,
    "progress":0.329492,
    "timeTotal":65.410113,
    "timeEstimation":133.458130,

    "isSequencerEmpty":false,
    "isMasterBusy":true,
    "isBackgroundBusy":true,
    "changeCounter":0,

    "errorCode":0,
    "errorMessage":""
}
```
When isMasterBusy becomes false, processing is done. It's easy to get in a stuck state.

## License Requirements

RealityScan is proprietary Epic software and is not redistributed by this repository. Use is governed by RealityScan's software license.

As of 3/19/2026, RealityScan 2.1 is free to use for individuals and small businesses that made less than $1 million USD in revenue in the past 12 months, educational institutions, and students. A RealityScan or Unreal Subscription is required for organizations that exceed these thresholds.
