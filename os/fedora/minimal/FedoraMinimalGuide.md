# Overview
In order to run `Fedora` on TinkerBoard 2s, we'll need to do some replacements from the `Fedora.raw` images that is available to us. 
Perform the first three steps to download the raw image file itself, extract it to a `.raw` file, and then mount it on a `/dev/loopX` device. 

```shell
curl https://download.fedoraproject.org/pub/fedora/linux/releases/40/Spins/aarch64/images/Fedora-Minimal-40-1.14.aarch64.raw.xz -o ~/Downloads
tar -zvxf ~/Downloads/Fedora-Minimal-40-1.14.aarch64.raw.xz
sudo losetup /dev/loop0 Fedora-Minimal-40-1.14.aarch64.raw

sudo fdisk -l /dev/loop0  
```
This will give you the below breakdown:
```shell
Disk /dev/loop0: 4.2 GiB, 4514119680 bytes, 8816640 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xc1748067

Device       Boot   Start     End Sectors  Size Id Type
/dev/loop0p1 *      18432  428031  409600  200M  6 FAT16
/dev/loop0p2       428032 2525183 2097152    1G 83 Linux
/dev/loop0p3      2525184 8816639 6291456    3G 83 Linux
```
Looks like `p1` = grub boot, `p2` = kernel boot, `p3` = rootfs. 

This is now super simple! We just need `p3` since through the `boot` options [here](../../../boot), you'll have already build the required boot and partition structure. 
So all we need to do is:
```shell
sudo dd if=/dev/loop0 of=rootfs.img bs=512 skip=2525184 count=6291456 conv=fsync status=progress && sync
```

Then let's refine the partition structure with the below:
```shell
sudo parted -s /dev/sdb mklabel gpt
# idbloader does not need a partition. In line with what Asus engineers are doing.
sudo parted /dev/sdb unit s mkpart uboot 16384 24575
sudo parted /dev/sdb unit s mkpart trust 24576 32767
sudo parted /dev/sdb unit s mkpart misc 32768 40959
sudo parted /dev/sdb unit s mkpart boot 40960 172031
sudo parted /dev/sdb unit s mkpart userdata ext2 172032 1024000  # 500 MB for userdata (mounted at /boot)
sudo parted /dev/sdb unit s mkpart rootfs ext4 1024001 21995521   # 10 GB for rootfs

sudo mkfs.ext2 /dev/sdb5
sudo mkfs.ext4 /dev/sdb6

sudo parted /dev/sdb print
```

Finally, we just need to write it all in :) 
```shell
DEVICE="/dev/sdb"
sudo dd if=idbloader.img of="$DEVICE" seek=64 conv=fsync status=progress && sync  # no partition for idbloader. just skip first 64 bytes
sudo dd if=uboot.img of="$DEVICE"1 conv=fsync status=progress && sync
sudo dd if=trust.img of="$DEVICE"2 conv=fsync status=progress && sync
# /dev/sdX3 is misc
sudo dd if=boot.img of="$DEVICE"4 conv=fsync status=progress && sync
sudo dd if=userdata.img of="$DEVICE"5 conv=fsync status=progress && sync
sudo dd if=rootfs.img of="$DEVICE"6 conv=fsync status=progress && sync
```

Once you launch it, there will be some questions you'll have to answer as part of the installation set up. like username creation and passwords, etc. 
Alternatively, you can run the [initialStartup.sh](initialStartup.sh) script which will do all these in a `chroot` env for you before booting up the board. 

NOTE: Remember to copy over the `kernelModules.tar.gz` that were extracted from boot to load into `/lib/modules/`.