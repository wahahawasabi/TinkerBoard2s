#!/usr/bin/env bash

# Done outside of chroot - package of the rootfs OS
dd if=/dev/zero of=rootfs.img bs=1M count=2048  # 1. Generate an Empty 2GB Image File
mkfs.ext4 rootfs.img                            # 2. Format the Image File as ext4
mkdir /mnt/rootfs
mount rootfs.img /mnt/rootfs       # 3. Mount the Image File
cp -rfp /path/to/rootfs/* /mnt/rootfs/     # 4. Copy the Root Filesystem into the Image
umount /mnt/rootfs                         # 5. Unmount the Image File
fsck.ext4 -f rootfs.img                         # 6. Check the Image for Errors
# 7. Resize the Image File to the Smallest Size
resize2fs -M rootfs.img                         # Check the minimum size needed by the filesystem
fsck.ext4 -f rootfs.img                         # 6. Check the Image for Errors
