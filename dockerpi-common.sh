#/bin/bash

RASPBERRY_VERSION=1

ZIP_URL="http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14/2020-02-13-raspbian-buster-lite.zip"
ZIP_SHA256="12ae6e17bf95b6ba83beca61e7394e7411b45eba7e6a520f434b0748ea7370e8"
ZIP_NAME="2020-02-13-raspbian-buster-lite.zip"
IMG_NAME="2020-02-13-raspbian-buster-lite.img"
IMG_NAME_MOD="filesystem.img"

TOOLCHAIN_PATH=/opt/pi-toolchain
ROOTFS_PATH=/opt/pi-rootfs
MOUNT_PATH=/opt/pi-mount
LOOP_NAME="/dev/loop0" # get empty loop device
PART_NAME="/dev/loop0p2" # get /dev/loop0p2 by fdisk -l $LOOP_NAME

ARTIFACTS_DIR=artifacts
ARTIFACT_ROOT_FS=pi-rootfs.tar.gz
ARTIFACT_TOOLCHAIN=pi-toolchain.tar.gz

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

