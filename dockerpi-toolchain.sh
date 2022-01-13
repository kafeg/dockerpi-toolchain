#/bin/bash

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

echo "Remove exists $TOOLCHAIN_PATH"

rm -rf $TOOLCHAIN_PATH

if [ -d "$TOOLCHAIN_PATH" ]
then
    echo "Unable to remove $TOOLCHAIN_PATH dir"
    exit 1
fi

docker build -f Dockerfile.toolchain --build-arg TOOLCHAIN_PATH_ARG=${TOOLCHAIN_PATH} --network=host -t dockerpi/toolchain .
docker run -v /opt:/opt/mount --rm dockerpi/toolchain bash -c "cp -r ${TOOLCHAIN_PATH} /opt/mount/"
${TOOLCHAIN_PATH}/bin/arm-linux-gnueabihf-cpp --version


