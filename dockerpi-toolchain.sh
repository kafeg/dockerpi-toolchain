#!/bin/bash

source ./dockerpi-common.sh

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

if [ ! -f "$IMG_NAME_MOD" ]
then
    echo "$IMG_NAME_MOD not exists"
    exit 1
fi

if [ ! -d "$ROOTFS_PATH" ]
then
    echo "$ROOTFS_PATH not exists"
    exit 1
fi

if [ -z "$TOOLCHAIN_PATH" ]
then
    echo "$ROOTFS_PATH not set"
    exit 1
fi

if [ -z "$TARGET_ARCH" ]
then
    echo "$TARGET_ARCH not set"
    exit 1
fi

echo "Remove exists $TOOLCHAIN_PATH"

rm -rf $TOOLCHAIN_PATH

if [ -d "$TOOLCHAIN_PATH" ]
then
    echo "Unable to remove $TOOLCHAIN_PATH dir"
    exit 1
fi

docker build -f Dockerfile.toolchain --build-arg TOOLCHAIN_PATH_ARG=${TOOLCHAIN_PATH} --build-arg TOOLCHAIN_ARCH_ARG=${TARGET_ARCH} --build-arg TOOLCHAIN_TARGET_ARG=${TOOLCHAIN_TARGET} --build-arg TOOLCHAIN_ARM_ARG=${TOOLCHAIN_ARM} --build-arg TOOLCHAIN_FLOAT_ARG="${TOOLCHAIN_FLOAT}" --network=host -t dockerpi/toolchain-${TARGET_ARCH} .
docker run -v /opt:/opt/mount --rm dockerpi/toolchain-${TARGET_ARCH} bash -c "cp -r ${TOOLCHAIN_PATH} /opt/mount/"
${TOOLCHAIN_PATH}/bin/${TOOLCHAIN_TARGET}-cpp --version


