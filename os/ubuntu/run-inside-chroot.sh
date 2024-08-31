# Username and Password variables
USERNAME=jakew
PASSWORD=1234
ROOTPASS=@1234
HOSTNAME=tk0

echo "root:$ROOTPASS" | chpasswd  # add password to root
useradd -m $USERNAME  # adding a new user
echo "$USERNAME:$PASSWORD" | chpasswd  # creating the password for the user
adduser $USERNAME sudo   # adding the user to sudo group. Fhen can do sudo with it.
usermod --shell /bin/bash $USERNAME # set bash as your default shell

# adding additional sources
echo "deb http://sg.ports.ubuntu.com/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list  # Add the below sources in instead of the existing.
echo "deb http://sg.ports.ubuntu.com/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list  # Add the below sources in instead of the existing.

# working with hostname
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

# Updating interfaces
cat <<EOF >> /etc/fstab
# <file system>                 <mount pt>              <type>          <options>               <dump>  <pass>
/dev/root                       /                       auto            rw,noauto               0       1
tmpfs                           /tmp                    tmpfs           mode=1777               0       0
tmpfs                           /run                    tmpfs           mode=0755,nosuid,nodev  0       0
PARTLABEL=userdata              /userdata               ext2            defaults                0       2
proc                            /proc                   proc            defaults                0       0
devtmpfs                        /dev                    devtmpfs        defaults                0       0
devpts                          /dev/pts                devpts          mode=0620,ptmxmode=0666,gid=5   0 0
tmpfs                           /dev/shm                tmpfs           nosuid,nodev,noexec     0       0
sysfs                           /sys                    sysfs           defaults                0       0
debugfs                         /sys/kernel/debug       debugfs         defaults                0       0
pstore                          /sys/fs/pstore          pstore          defaults                0       0
EOF
cat <<EOF >> /etc/network/interfaces
# Include files from /etc/network/interfaces.d:
source /etc/network/interfaces.d/*

# Add the following (for ethernet):
auto lo eth0
allow-hotplug eth0
iface lo inet loopback
iface eth0 inet dhcp
EOF

rm /usr/bin/qemu-aarch64-static  # removed the qemu placed in.
exit  # exit chroot



# todo: the below isn't running
##perl: warning: Setting locale failed.
  #perl: warning: Please check that your locale settings:
  #        LANGUAGE = "en_SG:en",
  #        LC_ALL = (unset),
  #        LANG = "en_SG.UTF-8"
  #    are supported and installed on your system.
  #perl: warning: Falling back to the standard locale ("C").





#### my newer items here
apt-get install systemd -y

# check if it's installed correctly:
dpkg -L systemd | grep /sbin/init
# output: if nothing happens, manually write the link

# ensure that sbin/init is created, or put the symlink in.
ln -sf /lib/systemd/systemd /sbin/init
# or
ln -sf /usr/lib/systemd/systemd /sbin/init

# verify
ls -l /sbin/init
# output: lrwxrwxrwx 1 root root 20 date time /sbin/init -> /lib/systemd/systemd


# todo: network, fstab, hostname, users and passwords (root and user)