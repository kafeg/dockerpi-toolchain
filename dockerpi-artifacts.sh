#!/bin/bash

source ./dockerpi-common.sh

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

DMPWD=`pwd`
ARTIFACTS_PATH=$DMPWD/$ARTIFACTS_DIR
mkdir $ARTIFACTS_DIR 2> /dev/null
chmod 777 artifacts

echo "Creating artifacts..."

if [ ! -f "$ARTIFACTS_DIR/$ARTIFACT_ROOT_FS" ]
then
  echo "Creating $ARTIFACTS_DIR/$ARTIFACT_ROOT_FS"
  cd $ROOTFS_PATH/..
  tar -zcf $ARTIFACTS_PATH/$ARTIFACT_ROOT_FS `basename $ROOTFS_PATH`
  cd $DMPWD
  chmod 777 $ARTIFACTS_PATH/$ARTIFACT_ROOT_FS
else
  echo "$ARTIFACTS_DIR/$ARTIFACT_ROOT_FS already exists"
fi

if [ ! -f "$ARTIFACTS_DIR/$ARTIFACT_TOOLCHAIN" ]
then
  echo "Creating $ARTIFACTS_DIR/$ARTIFACT_TOOLCHAIN"
  
  cp arm-linux-toolchain.cmake $TOOLCHAIN_PATH/arm-linux-toolchain.cmake
  
  sed -i "s/RASPBERRY_VERSION_TPL/$RASPBERRY_VERSION_NUMBER/g" $TOOLCHAIN_PATH/arm-linux-toolchain.cmake
  sed -i "s|SYSROOT_PATH_TPL|$ROOTFS_PATH|g" $TOOLCHAIN_PATH/arm-linux-toolchain.cmake
  sed -i "s|TOOLCHAIN_DIR_TPL|$TOOLCHAIN_PATH|g" $TOOLCHAIN_PATH/arm-linux-toolchain.cmake
  chmod 777 $TOOLCHAIN_PATH/arm-linux-toolchain.cmake
  
  cd $TOOLCHAIN_PATH/..
  tar -zcf $ARTIFACTS_PATH/$ARTIFACT_TOOLCHAIN `basename $TOOLCHAIN_PATH`
  cd $DMPWD
  chmod 777 $ARTIFACTS_PATH/$ARTIFACT_TOOLCHAIN
else
  echo "$ARTIFACTS_DIR/$ARTIFACT_TOOLCHAIN already exists"
fi

cd artifacts
sha256sum $ARTIFACT_ROOT_FS > checksum-${TARGET_ARCH}.txt
sha256sum $ARTIFACT_TOOLCHAIN >> checksum-${TARGET_ARCH}.txt
chmod 777 checksum-${TARGET_ARCH}.txt
cd ..

ls -alh artifacts

