# dockerpi-toolchain

This project allows you to build custom rootfs based on Raspbian Buster, which can include your additional packages or other patches and compile custom toolchain based on `GCC 8` and `glibc 2.28`. In the end you will have cross-rootfs and cross-toolchain to build your software for arm-linux.

NOTE: Unfortunatelly it's impossible by easy way switch to older version of glibc 

Custom toolchain/rootfs generator, based on [dockerpi](https://github.com/lukechilds/dockerpi) and [raspi-toolchain](https://github.com/Pro/raspi-toolchain)

Please check those links above to get info what each project does and about exists functionality and limitations.

The main goal of this project is to avoid manual command executing and automate everything what can be automated.

### How it works
So, `dockerpi-run-all.sh` is the main script in this repo which calls all other.

Let's describe what this project does step-by step, when you call `dockerpi-run-all.sh`, it calls:
- `dockerpi-modify.sh`
- - download and unpack `raspbian-buster-lite.zip`
- - inject `fisrtboot` script inside `raspbian-buster-lite.img` to automatic install software on first boot
- `docker run -v `pwd`:/sdcard/ lukechilds/dockerpi:vm`
- - start dockerpi container with custom `raspbian-buster-lite.img` in `qemu-arm` as described in [dockerpi](https://github.com/lukechilds/dockerpi) repo
- - execute `firstboot.sh` script and stop OS/container
- `dockerpi-extract.sh` 
- - extract rootfs, default to `/opt/pi-rootfs`
- - fixing relative links inside rootfs directory
- `dockerpi-toolchain.sh` 
- - build toolchain with same `glibc` version with `raspbian-buster-lite.img`
- - extract built toolchain, default to `/opt/pi-toolchain`
- `dockerpi-artifacts.sh`
- - creates directory artifacts
- - creates archives with built rootfs and toolchain: artifacts/pi-rootfs.tar.gz (~480MB), artifacts/pi-toolchain.tar.gz (~580MB)
- `dockerpi-clean.sh`
- - remove downloaded archive and all .img files
- - remove required docker images
- - remove extracted rootfs/toolchain (default `/opt/pi-rootfs` and `/opt/pi-toolchain`)

In the end you will get two `.tar.gz` files which can be used to cross-compile your software for arm-linux. You can export them and then use in CI.

### Usage
- `cd ~; git clone https://github.com/kafeg/dockerpi-toolchain.git; cd dockerpi-toolchain`
- `nano dockerpi-common.sh` - optional, adjust configuration before build, for e.g. packages list or output pathes
- `sudo ./dockerpi-run-all.sh` - build everything
- `sudo ./dockerpi-clean.sh` - clean up everything

### Configuration

Please check dockerpi-common.sh to adjust default configuration before call `sudo ./dockerpi-run-all.sh`.
By default PACKAGES_LIST contains everything required to cross-compile `vcpkg -> qt5-base` port

### How to cross-compile vcpkg ports

TODO ...

### How to cross-compile your software

TODO ...
