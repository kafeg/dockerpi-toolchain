#!/bin/bash

if [ -z "$PI_VER" ]
then
    RASPBERRY_VERSION=pi1
else
    RASPBERRY_VERSION=$PI_VER
fi

RASPBERRY_VERSION_NUMBER=`echo $RASPBERRY_VERSION | sed 's/pi//g'`

if [ "${RASPBERRY_VERSION}" = "pi1" ]
then
    TARGET_ARCH="armv6" # pi1
elif [ "${RASPBERRY_VERSION}" = "pi2" ]
then
    TARGET_ARCH="armv7" # pi2
else
    TARGET_ARCH="aarch64" # pi3
fi

ZIP_URL="http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip"
ZIP_SHA256="12ae6e17bf95b6ba83beca61e7394e7411b45eba7e6a520f434b0748ea7370e8"
ZIP_NAME="2020-02-13-raspbian-buster-lite.zip"
IMG_NAME="2020-02-13-raspbian-buster-lite.img"
IMG_NAME_MOD="filesystem-${TARGET_ARCH}.img"

TOOLCHAIN_PATH=/opt/pi-toolchain-${TARGET_ARCH}
ROOTFS_PATH=/opt/pi-rootfs-${TARGET_ARCH}
MOUNT_PATH=/opt/pi-mount-${TARGET_ARCH}
LOOP_NAME="/dev/loop0" # get empty loop device
PART_NAME="/dev/loop0p2" # get /dev/loop0p2 by fdisk -l $LOOP_NAME

ARTIFACTS_DIR=artifacts
ARTIFACT_ROOT_FS=pi-rootfs-${TARGET_ARCH}.tar.gz
ARTIFACT_TOOLCHAIN=pi-toolchain-${TARGET_ARCH}.tar.gz

PACKAGES_LIST="build-essential ninja-build apt-utils software-properties-common bison flex make curl unzip tar sed wget git yasm sed python libgl1-mesa-dev libglu1-mesa-dev libglu1-mesa-dev libxkbcommon-x11-dev libx11-dev libx11-xcb-dev mc nano libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0 libgles-dev libgles1 libgles2 libgles2-mesa-dev libegl-dev libegl-mesa0 libegl1 libegl1-mesa-dev gdb gdbserver"

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
  CNAME=rootfssetup-${TARGET_ARCH}
  docker kill $CNAME 2> /dev/null
  docker rm $CNAME 2> /dev/null
  docker run --name $CNAME -v `pwd`:/sdcard/ lukechilds/dockerpi:vm ${RASPBERRY_VERSION} &
  
  # wait until container stop but not more then N minutes (pi2/pi3 can't quit machines correctly https://github.com/lukechilds/dockerpi/pull/4)
  N=15
  MAX_MINUTES=0
  until [ "`docker inspect -f {{.State.Running}} $CNAME`"=="true" ]; do
    sleep 60;

	MAX_MINUTES=$((MAX_MINUTES+1))
	echo "Wait for $MAX_MINUTES of $N minutes"
	if [ $MAX_MINUTES -gt $N ] 
	then 
	  break 
	fi
  done;
  
  docker stop $CNAME
  docker kill $CNAME 2> /dev/null
  docker rm $CNAME 2> /dev/null
}
