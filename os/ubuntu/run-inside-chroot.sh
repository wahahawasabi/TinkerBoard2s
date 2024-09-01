#!/usr/bin/env bash

# Set your Username and Password variables.
USERNAME=tinker
PASSWORD=1234
ROOTPASS=@1234
HOSTNAME=tk0


install_init () {
  # responsible for initiating linux os. do not change this.
  apt-get install systemd -y
  ln -sf /lib/systemd/systemd /sbin/init
  # Check if the output of `ls -l /sbin/init` contains the specified string
  if ls -l /sbin/init | grep -q "/sbin/init -> /lib/systemd/systemd"; then
      return 0  # Return true (success)
  else
      return 1  # Return false (failure)
  fi
}


install_networking () {
  cat <<EOF >> /etc/network/interfaces
# This file is the main network interfaces file
# Loopback network interface
auto lo
iface lo inet loopback

# Include additional interface configurations
source /etc/network/interfaces.d/*
EOF

  # additional network interfaces configs - eth0, wlan0
  mkdir -p /etc/network/interfaces.d
  cat <<EOF >> /etc/network/interfaces.d/eth0.cfg
# Add the following (for ethernet):
auto lo eth0
allow-hotplug eth0
iface lo inet loopback
iface eth0 inet dhcp
EOF

  echo "networking interfaces written to file."
}


update_fstab () {
  # these are the recommended default settings
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

  echo "fstab updated"
}


update_user_permissions () {
  # Ensure required variables are set
  if [[ -z "$ROOTPASS" || -z "$USERNAME" || -z "$PASSWORD" || -z "$HOSTNAME" ]]; then
    echo "Error: Required variables ROOTPASS, USERNAME, PASSWORD, or HOSTNAME are not set."
    return 1  # Return false (failure)
  fi

  echo "root:$ROOTPASS" | chpasswd  # Set the root password
  useradd -m "$USERNAME"  # Add a new user with a home directory
  echo "$USERNAME:$PASSWORD" | chpasswd  # Set the password for the new user
  adduser "$USERNAME" sudo   # Add the user to the sudo group
  usermod --shell /bin/bash "$USERNAME" # Set bash as the default shell for the user

  hostname "$HOSTNAME"  # Temporarily change the hostname
  echo "$HOSTNAME" > /etc/hostname  # Permanently set the hostname

  # Append to /etc/hosts only if not already present
  if ! grep -q "127.0.0.1       $HOSTNAME" /etc/hosts; then
    cat <<EOF >> /etc/hosts
127.0.0.1       localhost
127.0.0.1       $HOSTNAME
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF
  fi
}


cleanup () {
  rm /usr/bin/qemu-aarch64-static
  # modprobe wifi & bluetooth driver

  echo "all done. leaving chroot."
  exit # leave chroot
}


# Run functions in sequence and check their success
if install_init && \
   install_networking && \
   update_fstab && \
   update_user_permissions; then

    echo "All functions completed successfully"
    cleanup  # Call cleanup only if all functions succeed
else
    echo "One or more functions failed"
    exit 1  # Exit with failure status
fi
