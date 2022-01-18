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
rm -f ./rootfssetup-${TARGET_ARCH}-cid
docker run --cidfile ./rootfssetup-${TARGET_ARCH}-cid -v `pwd`:/sdcard/ lukechilds/dockerpi:vm ${RASPBERRY_VERSION} &
CID=`cat ./rootfssetup-${TARGET_ARCH}-cid`
docker stop -t 1800 $CID # https://github.com/lukechilds/dockerpi/pull/4
rm -f ./rootfssetup-${TARGET_ARCH}-cid
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

