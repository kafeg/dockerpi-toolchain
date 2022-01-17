#/bin/bash

source ./dockerpi-common.sh

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

./dockerpi-modify.sh
[ $? -eq 0 ] || exit 1

mv $IMG_NAME_MOD filesystem.img
docker run -v `pwd`:/sdcard/ lukechilds/dockerpi:vm ${RASPBERRY_VERSION}
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

