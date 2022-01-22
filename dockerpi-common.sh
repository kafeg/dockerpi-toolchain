#!/bin/bash

if [ -z "$PI_VER" ]
then
    RASPBERRY_VERSION=pi1
else
    RASPBERRY_VERSION=$PI_VER
fi

if [ -z "$PACKAGES" ]
then
    # List from https://github.com/abhiTronix/raspberry-pi-cross-compilers/blob/master/QT_build_instructions.md#11-download-softwares--prepare-the-sd-card
    PACKAGES_LIST="build-essential ninja-build apt-utils software-properties-common bison flex make curl unzip tar sed wget git yasm sed python libgl1-mesa-dev libglu1-mesa-dev libglu1-mesa-dev libxkbcommon-x11-dev libx11-dev libx11-xcb-dev mc nano libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0 libgles-dev libgles1 libgles2 libgles2-mesa-dev libegl-dev libegl-mesa0 libegl1 libegl1-mesa-dev gdb gdbserver" 
	# gfortran pkg-config libxcb-randr0-dev libxcb-xtest0-dev libxcb-shape0-dev libxcb-xkb-dev
else
    PACKAGES_LIST=$PACKAGES
fi

if [ -z "$BDEPS" ]
then
	BUILD_DEP="" 
	# qt5-qmake libqt5gui5 libqt5webengine-data libqt5webkit5 libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0 gdbserver
else
    BUILD_DEP=$BDEPS
fi

RASPBERRY_VERSION_NUMBER=`echo $RASPBERRY_VERSION | sed 's/pi//g'`

if [ "${RASPBERRY_VERSION}" = "pi1" ]
then
    TARGET_ARCH="armv6" # pi1
elif [ "${RASPBERRY_VERSION}" = "pi2" ]
then
    TARGET_ARCH="armv7" # pi2
else
    # aarch64 -> Unknown arch used in --with-arch=aarch64 https://www.linuxquestions.org/questions/linux-from-scratch-13/gcc-first-build-unknown-architecture-aarch64-cross-compiling-for-raspberry-pi-4-a-4175691211/
    TARGET_ARCH="armv8-a" # pi3
fi

if [ "${RASPBERRY_VERSION}" = "pi3" ]
then
  # for aarch64 / arm64 rootfs
  ZIP_URL="http://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2020-08-24/2020-08-20-raspios-buster-arm64-lite.zip"
  ZIP_SHA256="0639c516aa032df314b176bda97169bdc8564e7bc5afd4356caafbc3f6d090ed"
  ZIP_NAME="2020-08-20-raspios-buster-arm64-lite.zip"
  IMG_NAME="2020-08-20-raspios-buster-arm64-lite.img"
else
  # for aarch32 / arm rootfs
  ZIP_URL="http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip"
  ZIP_SHA256="12ae6e17bf95b6ba83beca61e7394e7411b45eba7e6a520f434b0748ea7370e8"
  ZIP_NAME="2020-02-13-raspbian-buster-lite.zip"
  IMG_NAME="2020-02-13-raspbian-buster-lite.img"
fi

IMG_NAME_MOD="filesystem-${TARGET_ARCH}.img"

TOOLCHAIN_PATH=/opt/pi-toolchain-${TARGET_ARCH}
ROOTFS_PATH=/opt/pi-rootfs-${TARGET_ARCH}
MOUNT_PATH=/opt/pi-mount-${TARGET_ARCH}
LOOP_NAME="/dev/loop0" # get empty loop device
PART_NAME="/dev/loop0p2" # get /dev/loop0p2 by fdisk -l $LOOP_NAME

ARTIFACTS_DIR=artifacts
ARTIFACT_ROOT_FS=pi-rootfs-${TARGET_ARCH}.tar.gz
ARTIFACT_TOOLCHAIN=pi-toolchain-${TARGET_ARCH}.tar.gz

if [ "${TARGET_ARCH}" = "armv6" ]; then
    TOOLCHAIN_TARGET="arm-linux-gnueabihf"
elif [ "${TARGET_ARCH}" = "armv7" ]; then
    TOOLCHAIN_TARGET="arm-linux-gnueabihf"
else
    TOOLCHAIN_TARGET="aarch64-linux-gnu"
fi

if [ "${TARGET_ARCH}" = "armv6" ]; then
    TOOLCHAIN_ARM="arm"
	TOOLCHAIN_FLOAT="--with-fpu=vfp --with-float=hard"
elif [ "${TARGET_ARCH}" = "armv7" ]; then
    TOOLCHAIN_ARM="arm"
	TOOLCHAIN_FLOAT="--with-fpu=vfp --with-float=hard"
else
    TOOLCHAIN_ARM="arm64"
	TOOLCHAIN_FLOAT="" # hard float andvfp is a standard part of aarch64
fi

function mountimg {
  if [ -d "$MOUNT_PATH/bin" ]; then umount $MOUNT_PATH; fi
  if [ -f "$LOOP_NAME" ]; then losetup -d $LOOP_NAME; fi
  mkdir -p $MOUNT_PATH
  chmod 777 $MOUNT_PATH

  losetup $LOOP_NAME $IMG_NAME_MOD
  partprobe $LOOP_NAME
  mount -t ext4 -o rw,sync,nosuid,nodev,relatime,uhelper=udisks2 $PART_NAME $MOUNT_PATH

  if [ ! -d "$MOUNT_PATH/bin" ]
  then
    echo "Mount failed, exit..."
    if [ -d "$MOUNT_PATH/bin" ]; then umount $MOUNT_PATH; fi
    if [ -f "$LOOP_NAME" ]; then losetup -d $LOOP_NAME; fi
    exit 1
  fi

  echo "Mounted $IMG_NAME_MOD to $MOUNT_PATH"
}

function umountimg {
  umount $MOUNT_PATH
  losetup -d $LOOP_NAME
  sleep 1
  rmdir $MOUNT_PATH

  echo "Unmounted..."
}

function runandwaitcontainer {
  chmod a+x ./vm-entrypoint.sh
  docker build -f Dockerfile.vm -t dockerpi/rootfsvm .
  
  if [ "${RASPBERRY_VERSION}" = "pi1" ]
  then
    docker run -v `pwd`:/sdcard/ dockerpi/rootfsvm ${RASPBERRY_VERSION}
  else
    # we need to manually wait and kill container if it's type is pi2/pi3 (https://github.com/lukechilds/dockerpi/pull/4)
    MAX=$1
    docker run -v `pwd`:/sdcard/ dockerpi/rootfsvm ${RASPBERRY_VERSION} &
    sleep 1
    CID=`docker ps | grep dockerpi:vm | awk '{ print $1 }'`
    for i in $(seq 1 $MAX)
    do 
      echo "Wait $i of $MAX for container $CID"
	  sleep 60
    done
    docker stop $CID
  fi
}
