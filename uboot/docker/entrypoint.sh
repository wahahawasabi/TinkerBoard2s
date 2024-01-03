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

# References:
# https://tinker-board.asus.com/forum/index.php?/topic/15474-urgentdebian-11-3011tinkerboard-2s-tinkerboard-wont-boot-when-fiq_debuggeroff-and-without-wifibt-card/&tab=comments#comment-17010