#!/usr/bin/env bash

# Getting block IDs
rootfsMountPath="$(blkid -t PARTLABEL="rootfs" -o device)"
mkdir -p ~/debworkspace
# Mounting rootfs into point, with exec,dev options
sudo mount -o exec,dev "$rootfsMountPath" ~/debworkspace

sudo debootstrap --arch arm64 --foreign jammy ~/debworkspace/  # foreign is when you are doing the bootstrap from a different architecture machine
sudo cp /usr/bin/qemu-aarch64-static ~/debworkspace/usr/bin/  # this is required to virtualize this installation in the next step.
sudo chroot ~/debworkspace /usr/bin/qemu-aarch64-static /bin/bash -i  # enter into this installation as a root user
/debootstrap/debootstrap --second-stage  # this is only available / needed when --foreign is used (takes about 5-7 minutes)

# adding additional sources (overwrites)
cat <<EOF > /etc/apt/sources.list
deb http://sg.ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse
deb http://sg.ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse
deb http://sg.ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse
EOF

# Updating interfaces
cat <<EOF >> /etc/fstab
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
/dev/mmcblk1p7  /boot           ext2    defaults        0       1
/dev/mmcblk1p8  /               ext4    defaults        0       2
EOF

# Username and Password variables
USERNAME=jakew
PASSWORD=11junjie
ROOTPASS=@11Junjie
HOSTNAME=tk0

hostname $HOSTNAME  # change hostname
echo $HOSTNAME > /etc/hostname
cat <<EOF >> /etc/hosts
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF
echo "127.0.0.1       $(hostname)" >> /etc/hosts

echo "root:$ROOTPASS" | chpasswd  # add password to root
useradd -m $USERNAME  # adding a new user
echo "$USERNAME:$PASSWORD" | chpasswd  # creating the password for the user
adduser $USERNAME sudo   # adding the user to sudo group. Fhen can do sudo with it.
usermod --shell /bin/bash $USERNAME # set bash as your default shell

apt-get update && apt-get upgrade -y && apt-get install vim ssh curl dialog perl ifupdown net-tools ethtool udev wireless-tools iputils-ping resolvconf apt-utils wpasupplicant bsdmainutils pciutils  -y

cat <<EOF >> /etc/network/interfaces
# Add the following (for ethernet):
auto lo eth0
allow-hotplug eth0
iface lo inet loopback
iface eth0 inet dhcp
EOF

modprobe 8822ce  # enable wifi and bluetooth driver
sudo ifconfig wlp1s0 up  # turn it on
sudo ip link set wlp1s0 up  # allows for scanning

rm /usr/bin/qemu-aarch64-static

## wifi


#loading /lib/firmware/rockchip/dptx.bin failed with error -22

