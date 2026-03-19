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

## License Requirements

RealityScan is proprietary Epic software and is not redistributed by this repository. Use is governed by RealityScan's software license.

As of 3/19/2026, RealityScan 2.1 is free to use for individuals and small businesses that made less than $1 million USD in revenue in the past 12 months, educational institutions, and students. A RealityScan or Unreal Subscription is required for organizations that exceed these thresholds.