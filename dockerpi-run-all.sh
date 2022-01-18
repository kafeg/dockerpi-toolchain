#!/bin/bash

source ./dockerpi-common.sh

echo "RASPBERRY_VERSION=${RASPBERRY_VERSION}"
echo "TARGET_ARCH=${TARGET_ARCH}"

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

./dockerpi-modify.sh
[ $? -eq 0 ] || exit 1

mv $IMG_NAME_MOD filesystem.img

# we should run container twice to resize root filesystem and to install software/modify
# and we need to manually wait and kill container if it's type is pi2/pi3 (https://github.com/lukechilds/dockerpi/pull/4)

# resize and reboot
runandwaitcontainer 10

# install software/modify img
runandwaitcontainer 20

mv filesystem.img $IMG_NAME_MOD
[ $? -eq 0 ] || exit 1

./dockerpi-extract.sh
[ $? -eq 0 ] || exit 1

./dockerpi-toolchain.sh
[ $? -eq 0 ] || exit 1

./dockerpi-artifacts.sh
[ $? -eq 0 ] || exit 1

#./dockerpi-clean.sh № please run it separately if you need to cleanup everything after full build
#[ $? -eq 0 ] || exit 1

