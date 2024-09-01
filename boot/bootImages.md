# Boot flow from TinkerBoard into Linux rootfs

![Rockchip_bootflow20181122.jpg](pics/Rockchip_bootflow20181122.jpg)

With this in mind, we need to generate `idbloader`, `uboot`, `trust`, `kernel`. This example will follow `boot flow 1`

Note: `idbloader` is not needed to be in a partition because it will **seldom to never** be changed. 

# Building uboot.img & trust.img
Before building `uboot.img`, we need to make changes to [image-android.c](https://github.com/TinkerBoard-Linux/rockchip-linux-u-boot/blob/linux5.10-rk3399-debian11/common/image-android.c#L1152) file.
We need to modify it to be in line with our `rootfs` partition number, else the kernel will not be able to boot into it after loading into the kernel. 

**At any point in time if you want to clean the project and start again, you can run: ` make clean && make mrproper && make distclean`. This doesn't redo any `sed` changes you have made**

To do that, we can run:
```shell
cat /home/tk/uboot/common/image-android.c | grep mmcblk  # check result BEFORE sed 
# CHANGE NUMBER `6` TO THE PARTITION NUMBER OF YOUR ROOTFS
sed -i 's/mmcblk1p9/mmcblk1p6/g' /home/tk/uboot/common/image-android.c
sed -i 's/mmcblk0p9/mmcblk0p6/g' /home/tk/uboot/common/image-android.c

cat /home/tk/uboot/common/image-android.c | grep mmcblk  # check result AFTER sed
```

Next is to build the `uboot` image. we can do it automatically by running this code:
```shell
cd uboot
# build uboot and all required images.
./make.sh tinker_board_2 CROSS_COMPILE=aarch64-linux-gnu-
```
This will generate `trust.img`, `uboot.img`, `rk3399_loader_v1.30.128.bin`, `u-boot.dtb` files. 

`uboot.img` and `trust.img` are both used in the boot process as secondary loader. Next we will boot the primary loader `idbloader.img` 
with the files generated from uboot. `rk3399_loader_v1.30.128.bin` is mainly used for booting if you are using the `rkdevtool` which is not covered in this tutorial.

**IMPORTANT: Remember to make changes to your `rootfs` partition number before building uboot. Else it'll not be able to boot into rootfs** 

# Building idbloader.img
The general command if you are working on other rk builds is:
```shell
tools/mkimage -n rkxxxx -T rksd -d rkxx_ddr_vx.xx.bin idbloader.img
cat rkxx_miniloader_vx.xx.bin >> idbloader.img
```

for the actual ddr bin and miniloader bin used for the project, please refer to [rkboot/rk3399miniall.ini](https://github.com/TinkerBoard/rockchip-linux-rkbin/blob/linux4.19-rk3399-debian10/RKBOOT/RK3399MINIALL.ini)

As I am working on TinkerBoard 2s, it is based on `rk3399`. So creating `idbloader.img` will be:
```shell
../rkbin/tools/mkimage -n rk3399 -T rksd -d ../rkbin/bin/rk33/rk3399_ddr_800MHz_v1.30_DOE10.bin idbloader.img
cat ../rkbin/bin/rk33/rk3399_miniloader_v1.28_wd_rst_sd_1.8_v1.1.bin >> idbloader.img
```

# Building kernel.img
Next step we'll be building the `kernel` image. so from the `uboot` directory, we need to `cd ../kernel` 

We can build the `.config` file in 2 ways.
1. First way:
   ```shell  
   vim arch/arm64/configs/tinker_board_2_defconfig
   ```
    - EG: enabling `IPRoute settings` in the config
    - make changes: `# CONFIG_SECURITY is not set` -> `CONFIG_SECURITY=y`
        - Take a moment to review these kernel configs before adding them:
        - Add your specific configs in the `tinker_board_2_defconfig` file. Also be sure to google that the configs are able to work in `arm64` architecture.
          ```
          # IPRoute Settings
          CONFIG_SCSI_NETLINK=y
          CONFIG_NET_SCHED=y
          CONFIG_IP_MULTIPLE_TABLES=y
          ```
        - save changes with `ctrl + c` followed by `:wq`
          Build the `.config` file
2. Second way:
   ```shell
   make menuconfig
   ```
   Then you'll get a nice menu to select what kind of configs to edit. `y` for yes, `n` for no, `m` for make as modules

Once `.config` is build, make image. See Notes below on some menu items that is being asked.
```shell
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- tinker_board_2_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- rk3399-tinker_board_2.img -j24
# During this step, it MIGHT ask you a bunch of questions where you need to select n/y/?. Have to complete them to finish the build. 
# This happens because sometimes, there are some defconfig that was not included but the kernel requires it. So it'll prompt you for it.

make modules_install INSTALL_MOD_PATH=/home/tk/kernel/MODULES/  # modules will contain drivers like wifi, bluetooth, etc. 
tar czf kernelMods.tar.gz /home/tk/kernel/MODULES/
```

If  no errors, `boot.img`, `kernel.img`, `one-other-image.img` will be created in the directory.

# Extracting `userdata` contents from github source page
the `userdata`  content is found [here](https://github.com/TinkerBoard-Linux/rockchip-linux-device-rockchip/tree/linux5.10-rk3399-debian11/common/images/userdata/normal). 
As part of the `Dockerfile`, it has already been cloned into `rockchipDevice` folder. So all we need to do is to pull it out and put it into an image called `userdata.img` 
```shell
cd /home/tk/rockchipDevice
dd if=/dev/zero of=userdata.img bs=1M count=64                                      # 1. Generate an Empty 64mb Image File
mkfs.ext2 userdata.img                                                              # 2. Format the Image File as ext4
mkdir /mnt/userdata
mount userdata.img /mnt/userdata                                                    # 3. Mount the Image File
cp -rfp /home/tk/rockchipDevice/common/images/userdata/normal/* /mnt/userdata/      # 4. Copy the Root Filesystem into the Image
umount /mnt/userdata                                                                # 5. Unmount the Image File
fsck.ext2 -f userdata.img                                                           # 6. Check the Image for Errors
resize2fs -M userdata.img                                                           # 7. Resize the Image File to the Smallest Size
```

# Extracting it out from docker container to host computer
Within your host pc directory, you can run the below code to extract the required images:
```shell
docker cp <container_name>:/home/tk/uboot/idbloader.img . 
docker cp <container_name>:/home/tk/uboot/uboot.img . 
docker cp <container_name>:/home/tk/uboot/trust.img . 
docker cp <container_name>:/home/tk/kernel/boot.img .
docker cp <container_name>:/home/tk/kernel/kernelMods.tar.gz .
docker cp <container_name>:/home/tk/rockchipDevice/userdata.img .
```
Note: `kernelMods.tar.gz` will be loaded separately into the linux OS.  

# writing it to sd card / emmc

we'll to write this to /dev/sdX where X is the sd card identifier `blkid` or `lsblk`

 ```shell
 # if your installation is on SD Card:
sudo dd if=idbloader.img of=/dev/sdX seek=64 conv=fsync status=progress && sync  # no partition for idbloader. just skip first 64 bytes
sudo dd if=uboot.img of=/dev/sdX1 conv=fsync status=progress && sync
sudo dd if=trust.img of=/dev/sdX2 conv=fsync status=progress && sync
# /dev/sdX3 is misc
sudo dd if=boot.img of=/dev/sdX4 conv=fsync status=progress && sync
sudo dd if=userdata.img of=/dev/sdX5 conv=fsync status=progress && sync

 # if your installation is on emmc, we'll write this into `mmcblk0pX`:
sudo dd if=idbloader.img of=mmcblk0 seek=64 conv=fsync status=progress && sync  # no partition for idbloader. just skip first 64 bytes
sudo dd if=uboot.img of=mmcblk0p1 conv=fsync status=progress && sync
sudo dd if=trust.img of=mmcblk0p2 conv=fsync status=progress && sync
# mmcblk0p3 is misc 
sudo dd if=boot.img of=mmcblk0p4 conv=fsync status=progress && sync
sudo dd if=userdata.img of=mmcblk0p5 conv=fsync status=progress && sync
 ```

## References:
1. [rock-chip bootflow](http://opensource.rock-chips.com/wiki_Boot_option)
2. [asus forum - idbloader image source](https://tinker-board.asus.com/forum/index.php?/topic/15552-unable-to-boot-into-rootfs-after-building-uboot-and-kernel-from-source/&tab=comments#comment-17340)
3. [asus -forum - gcc info](https://tinker-board.asus.com/forum/index.php?/topic/15486-how-to-build-ubootimg-trustimg-and-flash-them-onto-an-empty-sd-card/&tab=comments#comment-17267)
