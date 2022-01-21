#!/bin/bash

source ./dockerpi-common.sh

DMPWD=`pwd`

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

if [ ! -f "/opt/$ZIP_NAME" ]
then
  echo "Downloading filesystem image to /opt/$ZIP_NAME"
  wget --quiet -O /opt/$ZIP_NAME $ZIP_URL
fi

echo $ZIP_SHA256 /opt/$ZIP_NAME | sha256sum -c

if [ $? -ne 0 ]
then
  echo "$ZIP_NAME has invalid hash. Please remove zip and img and download again"
  exit 1
fi

chmod 777 /opt/$ZIP_NAME

if [ -f "$IMG_NAME_MOD" ]
then
  echo "$IMG_NAME_MOD file already exists. Skip midification."
  exit 0
fi

echo "Modifying filesystem image $IMG_NAME"

if [ ! -f "$IMG_NAME" ]
then
  echo "Unzipping filesystem image"
  cp /opt/$ZIP_NAME ./
  unzip $ZIP_NAME
  rm $ZIP_NAME
fi

if [ ! -f "$IMG_NAME_MOD" ]
then
  # Reuse exists filesystem.img as cached with force until user will remove it
  mv $IMG_NAME $IMG_NAME_MOD
  echo "Move $IMG_NAME to $IMG_NAME_MOD"
else
  echo "Using exists $IMG_NAME_MOD"
fi

chmod 777 $IMG_NAME_MOD

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
#Type=oneshot
Type=simple
ExecStart=/firstboot.sh
RemainAfterExit=no
StandardOutput=tty
StandardError=tty
SyslogIdentifier=firstboot

[Install]
WantedBy=multi-user.target
EOT

# add helper scripts
cp ./resize.sh $MOUNT_PATH/
chmod a+x $MOUNT_PATH/resize.sh

# add firstboot script
rm -f $MOUNT_PATH/firstboot.sh
cat <<EOT >> $MOUNT_PATH/firstboot.sh
#!/bin/bash
#set -x

if [ ! -f /opt/resized ]
then
  echo "Resizing and reboot"
  sleep 5
  sudo apt-get update --allow-releaseinfo-change
  sudo apt-get install -y parted cloud-utils
  ls -alh /dev
  #sudo fdisk -l
  # pi1
  sudo /resize.sh /dev/sda 2 apply
  sudo resize2fs /dev/sda2
  
  # pi3
  #sudo /resize.sh /dev/mmcblk0 2 apply
  sudo growpart /dev/mmcblk0 2
  sudo resize2fs /dev/mmcblk0p2
  
  #sudo fdisk -l
  #sudo raspi-config nonint do_expand_rootfs # don't work and freeze on Pi1
  #sudo fdisk -l
  sleep 5
  touch /opt/resized
  sudo halt
  exit 0
fi

if [ ! -f /opt/modified ]
then
  echo "Install packages"
  sleep 15
  sudo sed -i "s/#deb-src/deb-src/g" /etc/apt/sources.list
  cat /etc/apt/sources.list
  sudo apt-get update --allow-releaseinfo-change
  sudo apt-get install -y $PACKAGES_LIST
  sudo apt-get build-dep -y $BUILD_DEP
  sudo apt-get autoremove -y
  sleep 30
  touch /opt/modified
  sudo halt
fi
EOT

chmod a+x $MOUNT_PATH/firstboot.sh

cd $MOUNT_PATH/etc/systemd/system/multi-user.target.wants/
rm -f ./firstboot.service
ln -s /etc/systemd/system/firstboot.service .

echo "'FirstBoot' service and script added/updated"

cd $DMPWD

umountimg

mv $IMG_NAME_MOD filesystem.img

# we should run container twice to resize root filesystem and to install software/modify
# and we need to manually wait and kill container if it's type is pi2/pi3 (https://github.com/lukechilds/dockerpi/pull/4)

# aarch64 emulation slower so we need more time to finish job
if [ "${RASPBERRY_VERSION}" = "pi3" ]
then
  WAIT_REBOOT=20
  WAIT_INSTALL=180
else
  WAIT_REBOOT=15
  WAIT_INSTALL=45
fi

# resize and reboot
runandwaitcontainer ${WAIT_REBOOT}

# install software/modify img
runandwaitcontainer ${WAIT_INSTALL}

mv filesystem.img $IMG_NAME_MOD
