#!/usr/bin/env bash

# Set your Username and Password variables.
USERNAME=tinker
PASSWORD=1234
ROOTPASS=@1234
HOSTNAME=tk0


# initial

mknod /dev/null c 1 3
chmod 666 /dev/null  # creating /devl/null so that chroot can perform `apt-get update`
echo "nameserver 1.1.1.1" >> etc/resolv.conf  # for initial. will be replaced later.
apt-get update

# core libraries installation
apt-get install -y systemd sudo vim curl ethtool dnsutils udev iputils-ping apt-utils wpasupplicant kmod pciutils tar
ln -sf /lib/systemd/systemd /sbin/init  # link to sbin/init for compatibility

# user details set up
echo "root:$ROOTPASS" | chpasswd  # Set the root password
useradd -m "$USERNAME"  # Add a new user with a home directory
echo "$USERNAME:$PASSWORD" | chpasswd  # Set the password for the new user
adduser "$USERNAME" sudo   # Add the user to the sudo group
usermod --shell /bin/bash "$USERNAME" # Set bash as the default shell for the user

# network management
networkctl end0 up  # bring up local ethernet
networkctl wlp1s0 up  # bring up wifi (might need to do this later onboard itself after doing modprobe)

# creating network configs - inline with systemd-networkd
cat <<EOF >> /etc/systemd/network/20-wlan.network
[Match]
Name=wlp1s0

[Network]
DHCP=yes
EOF

cat <<EOF >> /etc/systemd/network/00-local.network
[Match]
Name=lo

[Network]
Address=127.0.0.1/8
EOF

cat <<EOF >> /etc/systemd/network/10-end.network
[Match]
Name=end* eth* enp*

[Network]
DHCP=yes
EOF

# Set up fstab
cat <<EOF >> /etc/fstab
# <file system>                 <mount pt>              <type>          <options>                          <dump>  <pass>
PARTLABEL=userdata              /boot                   ext2            defaults                            0       1
PARTLABEL=rootfs                /                       ext4            defaults                            0       2
tmpfs                           /tmp                    tmpfs           defaults,noatime,mode=1777          0       0
tmpfs                           /run                    tmpfs           defaults,mode=0755,nosuid,nodev     0       0
sysfs                           /sys                    sysfs           defaults                            0       0
proc                            /proc                   proc            defaults                            0       0
devtmpfs                        /dev                    devtmpfs        defaults                            0       0
EOF

# set up hostname
hostname "$HOSTNAME"  # Temporarily change the hostname
echo "$HOSTNAME" > /etc/hostname  # Permanently set the hostname

# Append to /etc/hosts only if not already present
cat <<EOF >> /etc/hosts
127.0.0.1       localhost
127.0.0.1       $HOSTNAME
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

# cLean up
rm /usr/bin/qemu-aarch64-static

############## IMPORTANT ##############
# remember to copy the kernelMods.tar.gz into /lib/modules/kernel-version-number. you will need to make modules folder
#######################################

# boot up the board, login, and fun finalsteps.sh
cat <<EOF >> /finalsteps.sh
sudo modprobe 8822ce  # for activating wifi driver LATER
systemctl enable systemd-networkd.service
systemctl start systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl start systemd-resolved.service
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
networkctl status end0  # verify all ok
networkctl status wlp1s0  # verify all ok
EOF
chmod +x finalsteps.sh


#reference: https://tinker-board.asus.com/forum/index.php?/topic/15463-wlp1s0-not-found/