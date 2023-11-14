# Instruction guide on how to patch kernel 

It is required for the Tinker Engineers to provide the `dtb` files before we can proceed. until date, they have `dtb` for 4.4, 4.19, and 5.10 in the respective git repo below. 

- linaro gcc tested successfully:
    - [6.3-2017.05](https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/)
    - [6.4-2017.11](https://releases.linaro.org/components/toolchain/binaries/6.4-2017.11/aarch64-linux-gnu/)
    - [6.5-2018.12](https://releases.linaro.org/components/toolchain/binaries/6.5-2018.12/aarch64-linux-gnu/)
    - [7.5.0-2019](https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/) (we'll be using this in the `dockerfile`)
          
Terms:
1. Host Computer = your main computer (not TinkerBoard 2s)
2. Target Computer = TinkerBoard 2s.

## Patch existing kernel with updated configs (TinkerBoard 2s kernel code from [tinker repo kernel 4.4 ~ 4.19](https://github.com/TinkerBoard2/kernel/tree/linux4.19-rk3399-debian10), [tinker linux repo kernel 5.10](https://github.com/TinkerBoard-Linux/rockchip-linux-kernel.git))

1. Update the `Dockerfile` based on the required kernel that you want to utilize. The engineers put it in 2 separate repos... 
2. Note: Takes up to 10 minutes to clone from git. 
3. build the `dockerfile`. Make sure you are not using `arm64` platform in the docker build. it'll cause errors in the make process.
   ```shell
   cd directory/to/Dockerfile
   docker buildx build -f dockerfile-kernel-build --platform linux/amd64 -t tinkerkernel:v0.1 .
   docker run -it docker-image-id bash
    ```
   
4. clean the branch that you want to build from.
    ```shell
    cd /home/tinkeros/kernel
    git checkout linux4.19-rk3399-debian10
    make clean && make distclean && make mrproper -j16
    ```

5. build the `.config` file (2 ways)
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

6. Once `.config` is build, make image. See Notes below on some menu items that is being asked. 
    ```shell
    make ARCH=arm64 CROSS_COMPILE=/home/tinkeros/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- tinker_board_2_defconfig
   make ARCH=arm64 CROSS_COMPILE=/home/tinkeros/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- rk3399-tinker_board_2.img -j16
   # During this step, it MIGHT ask you a bunch of questions where you need to select n/y/?. Have to complete them to finish the build. 
   # This happens because sometimes, there are some defconfig that was not included but the kernel requires it. So it'll prompt you for it.
   
   make modules_install INSTALL_MOD_PATH=/home/tinkeros/kernel/MODULES/  # modules will contain drivers like wifi, bluetooth, etc. 
   tar czf name_of_archive_file.tar.gz name_of_directory_to_tar
    ```
7. If no errors, `boot.img`, `kernel.img`, `one-other-image.img` will be created in the directory (`/home/tinkeros/`).

8. Extract `boot.img` out from docker into host machine, and copy it to Target Computer.
    ```shell
    docker cp container-id:/path/boot.img ~/Desktop/boot.img
    scp ~/Desktop/boot.img linaro@192.168.1.1:~/Downloads  # copy over to Target Computer
       
    # if your installation is on SD Card, we'll need to write this `boot.img` into `mmcblk1p4`:
    sudo dd if=boot.img of=/dev/mmcblk1p4 status=progress && sync 
   
    # if your installation is on Emmc, we'll need to write this `boot.img` into `mmcblk0p4`:
    sudo dd if=boot.img of=/dev/mmcblk0p4 status=progress && sync 
    ```
9. Restart your Target Computer with `sudo reboot`. It'll be able to launch with a patched kernel.

10. Additional steps to show what to do next with `apparmor` as the example:
   ```shell
    # This step is for enabling of `apparmor` and other boot params.
    sudo vim /boot/cmdline.txt
    apparmor=1 security=apparmor    
    systemd.unified_cgroup_hierarchy=1  # 1 = cgroupV2 , 0 = cgroupV1    
    # check if i'm using cgroup v2 => stat -fc %T /sys/fs/cgroup/ OR cat /sys/fs/cgroup/cgroup.controllers
   ```
