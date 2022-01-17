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
- `cd ~; git clone https://github.com/kafeg/dockerpi-toolchain.git; cd dockerpi-toolchain; chmod a+x ./*.sh`
- `nano dockerpi-common.sh` - optional, adjust configuration before build, for e.g. packages list or output pathes
- `sudo ./dockerpi-run-all.sh` - build everything
- `sudo ./dockerpi-clean.sh` - clean up everything

### Configuration

Please check dockerpi-common.sh to adjust default configuration before call `sudo ./dockerpi-run-all.sh`.
By default PACKAGES_LIST contains everything required to cross-compile `vcpkg -> qt5-base` port

### How to use in CI

This is a sample workflow for GitHub Actions, which build toolchain and then upload artifacts to S3. You can adapt it to your CI system.

```
name: build-arm-linux-toolchain-rootfs

# manual run only
on: workflow_dispatch

# NOTE: 
#  This workflow requires 'ghusr ALL=(ALL) NOPASSWD: ALL' in the /etc/sudoers file, then you can remove it again and just use complete artifacts
#  This workflow requires `aws-cli` and `docker`, please install it by your system package manager

jobs:
  job:
    name: arm-linux-toolchain-rootfs
    runs-on: ubuntu-latest

    steps:
      - name: Checkout kafeg/dockerpi-toolchain
        uses: actions/checkout@v2
        with:
          repository: kafeg/dockerpi-toolchain
          path: dockerpi-toolchain

      - name: Build rootfs and toolchain
        run: |
          cd dockerpi-toolchain
          chmod a+x ./*.sh
          sudo ./dockerpi-run-all.sh
          sudo ./dockerpi-clean.sh

      - name: Upload to S3
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_BUCKET: sample_bucket
          AWS_DIR: arm-linux-toolchain
        run: |
          cd dockerpi-toolchain
          aws s3 cp artifacts/pi-rootfs.tar.gz s3://$AWS_BUCKET/$AWS_DIR/pi-rootfs.tar.gz
          aws s3 cp artifacts/pi-toolchain.tar.gz s3://$AWS_BUCKET/$AWS_DIR/pi-toolchain.tar.gz
          cd artifacts/
          sha256sum pi-rootfs.tar.gz > checksum.txt
          sha256sum pi-toolchain.tar.gz >> checksum.txt
          aws s3 cp checksum.txt s3://$AWS_BUCKET/$AWS_DIR/checksum.txt
```

### How to cross-compile vcpkg ports

To use vcpkg with built toolchain and cross-compile something you need to save `chainload` file and change vcpkg triplet `arm-linux`. Chainload file already prepared and placed inside `pi-toolchain.tar.gz`.

#### Sample to install package
1. Download `pi-rootfs.tar.gz` and `pi-toolchain.tar.gz`
2. git clone https://github.com/microsoft/vcpkg
3. ./vcpkg/bootstrap-vcpkg.sh
4. echo "set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE $ENV{ARM_LINUX_CHAINLOAD_PATH}/arm-linux-toolchain.cmake)" >> ./vcpkg/triplets/community/arm-linux.cmake
5. export ARM_LINUX_CHAINLOAD=/
6. ./vcpkg/vcpkg install qt5-base:arm-linux

### How to cross-compile your software

TODO ...
