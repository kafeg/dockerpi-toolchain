#/bin/bash

source ./dockerpi-common.sh

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

DMPWD=`pwd`
ARTIFACTS_PATH=$DMPWD/$ARTIFACTS_DIR
mkdir $ARTIFACTS_DIR
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
  cd $TOOLCHAIN_PATH/..
  tar -zcf $ARTIFACTS_PATH/$ARTIFACT_TOOLCHAIN `basename $TOOLCHAIN_PATH`
  cd $DMPWD
  chmod 777 $ARTIFACTS_PATH/$ARTIFACT_TOOLCHAIN
else
  echo "$ARTIFACTS_DIR/$ARTIFACT_TOOLCHAIN already exists"
fi

ls -alh artifacts

