#/bin/bash

source ./dockerpi-common.sh

DMPWD=`pwd`

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

if [ ! -f "$ZIP_NAME" ]
then
  echo "Downloading filesystem image"
  wget $ZIP_URL
fi

echo $ZIP_SHA256 $ZIP_NAME | sha256sum -c

if [ $? -ne 0 ]
then
  echo "$ZIP_NAME has invalid hash. Please remove it and download again"
  exit 1
fi

if [ ! -f "$IMG_NAME" ]
then
  echo "Unzipping filesystem image"
  unzip $ZIP_NAME
fi

chmod 777 $IMG_NAME $ZIP_NAME

if [ -f "$IMG_NAME_MOD" ]
then
  echo "$IMG_NAME_MOD file already exists. Skip midification."
  exit 0
fi

echo "Modifying filesystem image $IMG_NAME"

if [ ! -f "$IMG_NAME_MOD" ]
then
  # Reuse exists filesystem.img as cached with force until user will remove it
  cp $IMG_NAME $IMG_NAME_MOD
  echo "Copy $IMG_NAME to $IMG_NAME_MOD"
else
  echo "Using exists $IMG_NAME_MOD"
fi

chmod 777 $IMG_NAME $ZIP_NAME

mountimg

# add service
rm -f $MOUNT_PATH/etc/systemd/system/firstboot.service
cat <<EOT >> $MOUNT_PATH/etc/systemd/system/firstboot.service
[Unit]
Description=FirstBoot
After=network.target
Before=rc-local.service
ConditionFileNotEmpty=/firstboot.sh

[Service]
Type=oneshot
ExecStart=/firstboot.sh
RemainAfterExit=no
StandardOutput=tty
StandardError=tty
SyslogIdentifier=firstboot

[Install]
WantedBy=multi-user.target
EOT

# add script
rm -f $MOUNT_PATH/firstboot.sh
cat <<EOT >> $MOUNT_PATH/firstboot.sh
#!/bin/bash
#set -x
sleep 15
sudo apt-get update #--allow-releaseinfo-change
sudo apt-get install -y $PACKAGES_LIST
sudo apt-get autoremove -y
sleep 30
sudo halt
EOT

chmod a+x $MOUNT_PATH/firstboot.sh

cd $MOUNT_PATH/etc/systemd/system/multi-user.target.wants/
rm -f ./firstboot.service
ln -s /etc/systemd/system/firstboot.service .

echo "'FirstBoot' service and script added/updated"

cd $DMPWD

umountimg

echo "Finished. Next steps:"
echo "  docker run -it -v \`pwd\`/$IMG_NAME_MOD:/sdcard/filesystem.img lukechilds/dockerpi:vm ${RASPBERRY_VERSION}"
echo "  ./dockerpi-extract.sh"


