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
This will generate trust.img, uboot.img, rk3399_loader_v1.30.128.bin, u-boot.dtb files. 

`uboot.img` and `trust.img` are both used in the boot process as secondary loader. Next we will boot the primary loader `idbloader.img` 
with the files generated from uboot.

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
tar czf name_of_archive_file.tar.gz name_of_directory_to_tar
```

If  no errors, `boot.img`, `kernel.img`, `one-other-image.img` will be created in the directory.

# Extracting it out from docker to host computer
Within your host pc directory, you can run the below code to extract the required images:
```shell
docker cp <container_name>:/home/tk/kernel/boot.img .
docker cp <container_name>:/home/tk/uboot/uboot.img . 
docker cp <container_name>:/home/tk/uboot/trust.img . 
docker cp <container_name>:/home/tk/uboot/idbloader.img . 
```

# writing it to sd card / emmc

1. Extract `boot.img` out from docker into host machine, and copy it to Target Computer.
    ```shell
    docker cp container-id:/path/boot.img ~/Desktop/boot.img
    scp ~/Desktop/boot.img linaro@192.168.1.1:~/Downloads  # copy over to Target Computer
       
    # if your installation is on SD Card, we'll need to write this `boot.img` into `mmcblk1p4`:
    sudo dd if=boot.img of=/dev/mmcblk1p4 status=progress && sync 
   
    # if your installation is on Emmc, we'll need to write this `boot.img` into `mmcblk0p4`:
    sudo dd if=boot.img of=/dev/mmcblk0p4 status=progress && sync 
    ```
2. Restart your Target Computer with `sudo reboot`. It'll be able to launch with a patched kernel.

3. Additional steps to show what to do next with `apparmor` as the example:
   ```shell
    # This step is for enabling of `apparmor` and other boot params.
    sudo vim /boot/cmdline.txt
    apparmor=1 security=apparmor    
    systemd.unified_cgroup_hierarchy=1  # 1 = cgroupV2 , 0 = cgroupV1    
    # check if i'm using cgroup v2 => stat -fc %T /sys/fs/cgroup/ OR cat /sys/fs/cgroup/cgroup.controllers
   ```


## References:
1. [rock-chip bootflow](http://opensource.rock-chips.com/wiki_Boot_option)
2. [asus forum - idbloader image source](https://tinker-board.asus.com/forum/index.php?/topic/15552-unable-to-boot-into-rootfs-after-building-uboot-and-kernel-from-source/&tab=comments#comment-17340)
3. [asus -forum - gcc info](https://tinker-board.asus.com/forum/index.php?/topic/15486-how-to-build-ubootimg-trustimg-and-flash-them-onto-an-empty-sd-card/&tab=comments#comment-17267)
