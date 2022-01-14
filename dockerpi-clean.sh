#/bin/bash

source ./dockerpi-common.sh

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

umountimg

rm -rf $TOOLCHAIN_PATH
rm -rf $ROOTFS_PATH
rm -rf $MOUNT_PATH

rm -f *.zip
rm -f *.img

docker rmi dockerpi/toolchain -f
docker rmi lukechilds/dockerpi:vm -f
docker system prune -f


