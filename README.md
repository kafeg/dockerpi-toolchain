# dockerpi-toolchain

This project allows you to build custom rootfs based on Raspbian Buster, which can include your additional packages or other patches and compile custom toolchain based on `GCC 8` and `glibc 2.28`. In the end you will have cross-rootfs and cross-toolchain to build your software for arm-linux.

Custom toolchain/rootfs generator, based on [dockerpi](https://github.com/lukechilds/dockerpi) and [raspi-toolchain](https://github.com/Pro/raspi-toolchain)

Please check those links above to get info what each project does and about exists functionality and limitations.

The main goal of this project is to avoid manual command executing and automate everything what can be automated.

### Usage
- `cd ~; git clone https://github.com/kafeg/dockerpi-toolchain.git; cd dockerpi-toolchain; chmod a+x ./*.sh`
- `nano dockerpi-common.sh` - optional, adjust configuration before build, for e.g. packages list or output pathes
- to make ARMv6/aarch32 env:
- - `sudo PI_VER=pi1 ./dockerpi-run-all.sh` - build `ARMv6 / aarch32 toolchain` and `Raspbian aarch32 rootfs`
- - `sudo PI_VER=pi1 ./dockerpi-clean.sh` - clean up all cached stuff related to ARMv6 (optional)
- to make ARMv8-a/aarch64 env:
- - `sudo PI_VER=pi3 ./dockerpi-run-all.sh` - build `ARMv8-a / aarch64 toolchain` and `RaspiOS aarch64 rootfs`
- - `sudo PI_VER=pi3 ./dockerpi-clean.sh` - clean up all cached stuff related to ARMv8-a (optional)

### Configuration

Please check `dockerpi-common.sh` to adjust default configuration before call `sudo PI_VER=pi* ./dockerpi-run-all.sh`.

At lease you can change `PACKAGES_LIST`

### How to use in CI

This is a sample workflow for GitHub Actions, which build toolchain and then upload artifacts to S3. You can adapt it to your CI system.

```
name: build-arm-linux-toolchain

# manual run only
on: workflow_dispatch

# NOTE: 
#  This workflow requires 'ghusr ALL=(ALL) NOPASSWD: ALL' in the /etc/sudoers file, 
#  then you can remove it again and just use complete artifacts
#  This workflow requires `aws-cli` and `docker`, please install it by your system package manager

env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_BUCKET: sample_bucket
  AWS_DIR: arm-linux-toolchain

jobs:
  armv6-linux-toolchain:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout kafeg/dockerpi-toolchain
        uses: actions/checkout@v2
        with:
          repository: kafeg/dockerpi-toolchain
          path: dockerpi-toolchain

      - name: RasPi 1 -> Build rootfs and toolchain armv6 (aarch32)
        env:
          PI_VER: pi1
        run: |
          cd dockerpi-toolchain
          chmod a+x ./*.sh
          sudo ./dockerpi-run-all.sh
          #sudo ./dockerpi-clean.sh # (optional)

      - name: RasPi 1 -> Upload to S3 armv6 (aarch32)
        run: |
          cd dockerpi-toolchain
          aws s3 sync artifacts/ s3://$AWS_BUCKET/$AWS_DIR/ --quiet

  armv8-linux-toolchain:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout kafeg/dockerpi-toolchain
        uses: actions/checkout@v2
        with:
          repository: kafeg/dockerpi-toolchain
          path: dockerpi-toolchain

      - name: RasPi 3 -> Build rootfs and toolchain armv8 (aarch64)
        env:
          PI_VER: pi3
        run: |
          cd dockerpi-toolchain
          chmod a+x ./*.sh
          sudo ./dockerpi-run-all.sh
          #sudo ./dockerpi-clean.sh

      - name: RasPi 3 -> Upload to S3 armv8 (aarch64)
        run: |
          cd dockerpi-toolchain
          aws s3 sync artifacts/ s3://$AWS_BUCKET/$AWS_DIR/ --quiet
```

#### Sample artifacts on S3

![Sample artifacts on S3](https://github.com/kafeg/dockerpi-toolchain/raw/main/dockerpi-toolchain-artifacts.png)

### How to cross-compile vcpkg ports

To use vcpkg with built toolchain and cross-compile something you need to save `chainload` file and change vcpkg triplet `arm-linux`. Chainload file already prepared and placed inside `pi-toolchain.tar.gz`.

#### Sample to install package
1. Download and place artifacts to `/opt` like: `/opt/pi-rootfs-armv6.tar.gz`, `/opt/pi-toolchain-armv6.tar.gz`, `/opt/pi-rootfs-armv8-a.tar.gz`, `/opt/pi-toolchain-armv8-a.tar.gz`.
2. Extract artifacts: 
   - `cd /opt; rm -rf ./pi-*/; for f in pi-*.tar.gz; do tar -xvf "$f" > /dev/null; done`.
   - You should have 4 dirs now: `/opt/pi-rootfs-armv6/`, `/opt/pi-toolchain-armv6/`, `/opt/pi-rootfs-armv8-a/`, `/opt/pi-toolchain-armv8-a/`
3. `git clone https://github.com/microsoft/vcpkg`
4. `./vcpkg/bootstrap-vcpkg.sh`
5. ARMv6 / aarch32
   - `echo 'set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE $ENV{ARM_LINUX_CHAINLOAD_PATH}/arm-linux-toolchain.cmake)' >> ./vcpkg/triplets/community/arm-linux.cmake`
   - `export PATH=/opt/pi-toolchain-armv6/bin:/opt/pi-toolchain-armv6/libexec/gcc/arm-linux-gnueabihf/8.3.0:$PATH`
   - `export ARM_LINUX_CHAINLOAD_PATH=/opt/pi-toolchain-armv6`
   - `./vcpkg/vcpkg install zlib:arm-linux`
6. ARMv8-a / aarch64
   - `echo 'set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE $ENV{ARM_LINUX_CHAINLOAD_PATH}/arm-linux-toolchain.cmake)' >> ./vcpkg/triplets/community/arm64-linux.cmake`
   - `export PATH=/opt/pi-toolchain-armv8-a/bin:/opt/pi-toolchain-armv8-a/libexec/gcc/arm-linux-gnueabihf/8.3.0:$PATH`
   - `export ARM_LINUX_CHAINLOAD_PATH=/opt/pi-toolchain-armv8-a`
   - `./vcpkg/vcpkg install zlib:arm64-linux`

### How to cross-compile your software

TODO ...

### Advanced: How does it work internally
So, `dockerpi-run-all.sh` is the main script in this repo which calls all other.

Let's describe what this project does step-by step, when you call `dockerpi-run-all.sh`, it calls:
- `dockerpi-modify.sh`
- - download and unpack `raspbian-buster-lite.zip`
- - inject `fisrtboot` script inside `raspbian-buster-lite.img` to automatic install software on first boot
- `docker run -v `pwd`:/sdcard/ lukechilds/dockerpi:vm`
- - start dockerpi container with custom `raspbian-buster-lite.img` in `qemu-arm` as described in [dockerpi](https://github.com/lukechilds/dockerpi) repo
- - execute `firstboot.sh` script and stop OS/container
- `dockerpi-extract.sh` 
- - extract rootfs, default to `/opt/pi-rootfs-[armv6|armv8-a]`
- - fixing relative links inside rootfs directory
- `dockerpi-toolchain.sh` 
- - build toolchain with same `glibc` version with `raspbian-buster-lite.img`
- - extract built toolchain, default to `/opt/pi-toolchain`
- `dockerpi-artifacts.sh`
- - creates directory artifacts
- - creates archives with built rootfs and toolchain: artifacts/pi-rootfs-[armv6|armv8-a].tar.gz, artifacts/pi-toolchain-[armv6|armv8-a].tar.gz
- `dockerpi-clean.sh`
- - remove downloaded archives and all .img files
- - remove required docker images
- - remove extracted rootfs/toolchain (default `/opt/pi-rootfs-[armv6|armv8-a]` and `/opt/pi-toolchain-[armv6|armv8-a]`)

In the end you will get two `.tar.gz` files which can be used to cross-compile your software for arm-linux. You can export them and then use in CI.

NOTE: Unfortunatelly it's impossible by easy way switch to older version of glibc because it requires older versions of Rasbian/RaspiOS and all versions below `Buster` have errors in many stages, for e.g. on build toolchain or on install packages or doesn't contain some required packages and like that. At least older glibc can't be built with GCC 8 without many patches.
