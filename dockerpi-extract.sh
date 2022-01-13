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

echo "Remove exists $ROOTFS_PATH"

rm -rf $ROOTFS_PATH

if [ -d "$ROOTFS_PATH" ]
then
    echo "Unable to remove $ROOTFS_PATH dir"
    exit 1
fi

echo "Extracting filesystem image $IMG_NAME_MOD to $ROOTFS_PATH"

mountimg

mkdir $ROOTFS_PATH
cp -rp $MOUNT_PATH/* $ROOTFS_PATH

umountimg

echo "Fixing relative links in $ROOTFS_PATH"

rm -f ./fix-links.py
cat <<EOT >> ./fix-links.py
#!/usr/bin/env python
import sys
import os

topdir = sys.argv[1]
topdir = os.path.abspath(topdir)

def handlelink(filep, subdir):
  link = os.readlink(filep)
  if link[0] != "/":
    return
  if link.startswith(topdir):
    return
  #print("Replacing %s with %s for %s" % (link, os.path.relpath(topdir+link, subdir), filep))
  os.unlink(filep)
  os.symlink(os.path.relpath(topdir+link, subdir), filep)

for subdir, dirs, files in os.walk(topdir):
  for f in files:
    filep = os.path.join(subdir, f)
    if os.path.islink(filep):
      handlelink(filep, subdir)
EOT

chmod a+x ./fix-links.py
./fix-links.py $ROOTFS_PATH
rm -f ./fix-links.py

echo "Finished extracting. Next steps:"
echo "  ./dockerpi-toolchain.sh"


