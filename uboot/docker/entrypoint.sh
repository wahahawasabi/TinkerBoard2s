#!/usr/bin/env bash

# temp variables
tk2_defconfig="tinker_board_2_defconfig"
cd source && make "$tk2_defconfig"
# Be sure to change the gcc $PATH if you decide to use another version
make CROSS_COMPILE=/home/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
FILE=u-boot.img
if test -f "$FILE"; then
  echo "Compile done. Please retrieve file with: docker cp $(hostname):/home/source/u-boot.img . "
else
  echo "Compile failed."
fi





# extract the uboot that was build
sudo dd if=u-boot.img of=/dev/mmcblk1p1 status=progress && sync



# The u-boot image must be copied to the beginning of the device,
# skip 64 blocks for the location of the loader. This should be done in the tinkerimage.sh script

dd if=platform-asus/tinkerboard/u-boot/u-boot.img of=${LOOP_DEV} seek=64 conv=notrunc


# References:
# https://tinker-board.asus.com/forum/index.php?/topic/15474-urgentdebian-11-3011tinkerboard-2s-tinkerboard-wont-boot-when-fiq_debuggeroff-and-without-wifibt-card/&tab=comments#comment-17010