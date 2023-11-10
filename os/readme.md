## Fresh installation of Ubuntu

How does the partitions look like on target computer
```shell
linaro@linaro-alip:~$ sudo blkid
# --------------------------EMMC---------------------------------------------------
/dev/mmcblk2p1: PARTLABEL="uboot" PARTUUID="bfce4461-3e1f-4f26-90c2-3e969bd05d5d"
/dev/mmcblk2p2: PARTLABEL="trust" PARTUUID="5628c04f-2ef0-4c4a-8d55-bb2dce9513ba"
# --------------------------SD CARD------------------------------------------------
/dev/mmcblk1p1: PARTLABEL="uboot" PARTUUID="5e6c4af7-015f-46df-9426-d27fb38f1d87"
/dev/mmcblk1p2: PARTLABEL="trust" PARTUUID="06d92269-06ed-4b52-baa6-ad2c4b110fac"
/dev/mmcblk1p3: PARTLABEL="misc" PARTUUID="3b380e75-1faa-4d56-b191-6f7daba1c452"
/dev/mmcblk1p4: PARTLABEL="boot" PARTUUID="4c7fe12e-2f73-4909-8b5a-5f3c539fb852"
/dev/mmcblk1p5: PARTLABEL="recovery" PARTUUID="11f5d8bf-4daa-4166-9af9-b9d6ba2427ca"
/dev/mmcblk1p6: PARTLABEL="backup" PARTUUID="3c942069-c008-4b55-9d9a-7110c30151ab"
/dev/mmcblk1p7: PARTLABEL="splash" PARTUUID="3135f845-1317-4d7a-b1bb-d1aa70d740cb"
/dev/mmcblk1p8: UUID="5f38be2e-3d5d-4c42-8d66-8aa6edc3eede" BLOCK_SIZE="1024" TYPE="ext2" PARTLABEL="userdata" PARTUUID="dceeb110-7c3e-4973-b6ba-c60f8734c988"
/dev/mmcblk1p9: UUID="51e83a43-830f-48de-bcea-309a784ea35c" BLOCK_SIZE="4096" TYPE="ext4" PARTLABEL="rootfs" PARTUUID="c58164a5-704a-4017-aeea-739a0941472f"
```
So we want to format `rootfs` and install over the custom Debian image.

How does it look like on the host computer (jacking in the SD card into the host computer)
```shell
sudo blkid
# ...
# ... various other hard disks currently attached to the host computer
# ...
/dev/sdb1: PARTLABEL="uboot" PARTUUID="5e6c4af7-015f-46df-9426-d27fb38f1d87"
/dev/sdb2: PARTLABEL="trust" PARTUUID="06d92269-06ed-4b52-baa6-ad2c4b110fac"
/dev/sdb3: PARTLABEL="misc" PARTUUID="3b380e75-1faa-4d56-b191-6f7daba1c452"
/dev/sdb4: PARTLABEL="boot" PARTUUID="4c7fe12e-2f73-4909-8b5a-5f3c539fb852"
/dev/sdb5: PARTLABEL="recovery" PARTUUID="11f5d8bf-4daa-4166-9af9-b9d6ba2427ca"
/dev/sdb6: PARTLABEL="backup" PARTUUID="3c942069-c008-4b55-9d9a-7110c30151ab"
/dev/sdb7: PARTLABEL="splash" PARTUUID="3135f845-1317-4d7a-b1bb-d1aa70d740cb"
/dev/sdb8: UUID="5f38be2e-3d5d-4c42-8d66-8aa6edc3eede" BLOCK_SIZE="1024" TYPE="ext2" PARTLABEL="userdata" PARTUUID="dceeb110-7c3e-4973-b6ba-c60f8734c988"
/dev/sdb9: UUID="51e83a43-830f-48de-bcea-309a784ea35c" BLOCK_SIZE="4096" TYPE="ext4" PARTLABEL="rootfs" PARTUUID="c58164a5-704a-4017-aeea-739a0941472f"
```

1. We don't have to create a `dockerfile` for this instance. We can do it locally on the host computer.
2. Assuming we have already installed a copy of `Debian` (from Asus website) on the target computer (because of all the partitioning and boots that it provides.).
   We're going to format `/dev/sdb9` since it is the `fs` portion, and install `Ubuntu` over it.
3. use GParted to format `/dev/sdb9` and resize to make full use of sd card if required.
4. mount `/dev/sdb9` into a workspace: `sudo mount -o exec,dev /dev/sdb9 debworkspace`
    1. note: `exec,dev` is required for this operations.
    2. note: `debworkspace` is a folder you'll have to create. eg: `mkdir ~/debworkspace`
5. Bootstrap Process:
   ```shell
   sudo debootstrap --arch arm64 --foreign jammy ~/debworkspace/  # foreign is when you are doing the bootstrap from a different architecture machine
   sudo cp /usr/bin/qemu-aarch64-static ~/debworkspace/usr/bin/  # this is required to virtualize this installation in the next step.
   sudo chroot ~/debworkspace /usr/bin/qemu-aarch64-static /bin/bash -i  # enter into this installation as a root user
   /debootstrap/debootstrap --second-stage  # this is only available / needed when --foreign is used (takes about 5-7 minutes)
   
   # mandatory steps
   apt-get install vim openssh-server
   passwd # set password for root user
   vim /etc/hostname 
   # modify desktop to new hostname
   vim /etc/fstab
   # add in for booting
   # this is based on the above blkid items. 
   # <file system> <mount point>   <type>  <options>       <dump>  <pass>
   /dev/mmcblk1p8  /boot           ext2    defaults        0       1
   /dev/mmcblk1p9  /               ext4    defaults        0       2
   
   vim /etc/hosts
   # add the below line in.
   127.0.0.1    $HOSTNAME 

   systemctl enable serial-getty@ttyS0.service
   
   # update locales
   apt-get install dialog perl  # We need those installed first to correct some error messages about locale: If locale-gen command is missing, apt-get install locales first.
  
   # might have to add this at final steps 
   vim /etc/network/interfaces
   # Add the following (for ethernet):
   auto lo eth0
   allow-hotplug eth0
   iface lo inet loopback
   iface eth0 inet dhcp
   
   useradd -m myuser  # adding a new user
   echo myuser:mypassword | chpasswd  # creating the password for the user
   adduser myuser sudo  # adding the user to sudo group. Then can do sudo with it. 
   usermod --shell /bin/bash myuser # set bash as your default shell
   
   ###############################
   # NOT MANDATORY BUT RECOMMENDED
   ###############################
   vim /etc/apt/sources.list  # Add the below sources in instead of the existing. 
   deb http://sg.ports.ubuntu.com/ jammy main restricted universe multiverse
   # deb-src http://sg.ports.ubuntu.com/ jammy main restricted universe multiverse
   deb http://sg.ports.ubuntu.com/ jammy-updates main restricted universe multiverse
   # deb-src http://sg.ports.ubuntu.com/ jammy-updates main restricted universe multiverse
   
   apt-get install ifupdown net-tools ethtool udev wireless-tools iputils-ping resolvconf wget apt-utils wpasupplicant bsdmainutils # good tools to have

   ##########################
   # NOT MANDATORY BUT USEFUL
   ##########################

   # for root login
   vim /etc/ssh/sshd_config
   #PermitRootLogin prohibit-password` -> uncomment and change to  `PermitRootLogin yes
   
   ###########
   # CLEAN UP
   ###########
   rm /usr/bin/qemu-aarch64-static
   ``` 
This gives you a BASIC ubuntu desktop to work with. no gui is installed (i think). so you'll want to download GNOME. I'm using it as a server so have no need for GUI.
Additional inputs welcome for This section if you are interested to update it.

## Errors / Warnings:
1. Installing Ubuntu comes up with this warning:
    1. `/proc/ is not mounted, but required for successful operation of systemd-tmpfiles. Please mount /proc/. Alternatively, consider using the --root= or --image= switches.`
