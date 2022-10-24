
This document serves as a guide for updating TinkerBoard 2s OS kernels. I invite anyone who is playing around with TinkerBoard 2s to test this and
add on more information where applicable! :) 

Content:
- Kernel Patching
  - Patch existing 4.19 kernel with updated configs
    - linaro gcc tested successfully:
      - [6.3-2017.05](https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/)
      - [6.4-2017.11](https://releases.linaro.org/components/toolchain/binaries/6.4-2017.11/aarch64-linux-gnu/) 
      - [6.5-2018.12](https://releases.linaro.org/components/toolchain/binaries/6.5-2018.12/aarch64-linux-gnu/)
      - [7.5.0-2019](https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/) (we'll be using this in the `dockerfile`)
  - Create new kernel 5.4.219 from mainline kernel
  - Create new kernel 5.10.149 from kernel.org
  - Create new kernel 5.15.74 from kernel.org
- Fresh installation of Ubuntu 

Terms:
1. Host Computer = your main computer (not TinkerBoard 2s)
2. Target Computer = TinkerBoard 2s. 

## Patch existing 4.19 kernel with updated configs (TinkerBoard 2s kernel code from [tinker repo](https://github.com/TinkerBoard2/kernel/tree/linux4.19-rk3399-debian10))

1. We'll use a `dockerfile` with the right installs on the Host Computer to perform the kernel patching. 
    ```dockerfile
    FROM ubuntu:jammy-20221003

    RUN apt-get update && apt-get upgrade -y && \
    # Install required libs
    apt-get install -y ca-certificates procps curl vim xz-utils git wget \
    bison flex make bc build-essential libncurses-dev libssl-dev libelf-dev liblz4-tool \
    python-is-python3 && \
    # get the gcc  \
    wget https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz --directory /home/tinkeros/ &&\
    # Setup gcc
    tar -xvf /home/tinkeros/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz --directory /home/tinkeros/ &&\
    rm /home/tinkeros/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz &&\
    git clone https://github.com/TinkerBoard2/kernel.git /home/tinkeros/kernel/ --progress
    
    # adding gcc to path
    ENV PATH="${PATH}:/home/tinkeros/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin"
    
    ########### References ###########
    # https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/
    # Note: https://tinker-board.asus.com/forum/index.php?/topic/14988-kernel-build-error-lz4c/
    ```
   
    Note: Takes up to 10 mins to clone from git. 

   build the `dockerfile`. Make sure you are not using `arm64` platform in the docker build. it'll cause errors in the make process. 
   ```shell
   cd directory/to/dockerfile
   docker buildx build -f dockerfile-kernel-build --platform linux/amd64 -t kernel4.19-test1 .
   docker run -it docker-image-id bash
    ```

2. enter container with `docker run -it <container-id> bash`
    ```shell
    cd /home/tinkeros/kernel
    git checkout linux4.19-rk3399-debian10
    make clean && make distclean && make mrproper -j16
    ```

3. build the `.config` file
    ```shell  
    vim arch/arm64/configs/tinker_board_2_defconfig
    ```
    - EG: enabling `apparmor` in the config 
    - Search for `CONFIG_SECURITY` in `vim` with `/CONFIG_SECURITY`
    - make changes: `# CONFIG_SECURITY is not set` -> `CONFIG_SECURITY=y`
      - Take a moment to review these kernel configs before adding them:
      - Add your specific configs in the `tinker_board_2_defconfig` file. Also be sure to google that the configs are able to work in `arm64` architecture. 
        EG: `CONFIG_HUGETLB` is not available on arm devices.
        ```lombok.config
        # AppArmor Config
        CONFIG_SECURITY=y
        CONFIG_SECURITY_APPARMOR=y
        CONFIG_DEFAULT_SECURITY="apparmor" 
        CONFIG_SECURITY_APPARMOR_BOOTPARAM_VALUE=1
        CONFIG_SECURITY_APPARMOR_HASH=y
        CONFIG_SECURITY_APPARMOR_HASH_DEFAULT=y
        CONFIG_SECURITY_APPARMOR_DEBUG=y
        CONFIG_SECURITY_APPARMOR_DEBUG_ASSERTS=y
        CONFIG_SECURITY_APPARMOR_DEBUG_MESSAGES=y
        
        # Additional Configs that is being asked in kernel 4.19 (since tinker_board_2_defconfig was rolled out)
        CONFIG_AUDITSYSCALL=n
        CONFIG_NETLABEL=n
        CONFIG_NETFILTER_XT_TARGET_AUDIT=n
        CONFIG_IP_NF_SECURITY=n
        CONFIG_IP6_NF_SECURITY=n
        CONFIG_SECURITY_NETWORK_XFRM=n
        CONFIG_SECURITY_SELINUX=n
        CONFIG_SECURITY_SMACK=n
        CONFIG_SECURITY_TOMOYO=n
        CONFIG_SECURITY_LOADPIN=n
        CONFIG_SECURITY_YAMA=n
        CONFIG_INTEGRITY=n
        
        # Additional Configs for Cgroupv2
        # CONFIG_HUGETLB is not avalible on arm devices. 
        # CONFIG_PROC_PID_CPUSET=y  # CONFIG_CPUSETS=y  # seems like these 2 are already set 
        # tinker2 only has support for cgroupv1... to check with later kernels.
        ```
      - save changes with `ctrl + c` followed by `:wq`
    Build the `.config` file
   ```shell
   make ARCH=arm64 CROSS_COMPILE=/home/tinkeros/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- tinker_board_2_defconfig
   ```

4. make image. See Notes below on some menu items that is being asked.
    ```shell
   make ARCH=arm64 CROSS_COMPILE=/home/tinkeros/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- rk3399-tinker_board_2.img -j16
   # During this step, it MIGHT ask you a bunch of questions where you need to select n/y/?. Have to complete them to finish the build. 
   # This happens because sometimes, there are some defconfig that was not included but the kernel requires it. So it'll prompt you for it.
    ```
   
5. If no errors, `boot.img`, `kernel.img`, `one-other-image.img` will be created in the directory (`/home/tinkeros/`).

6. Extract `boot.img` out from docker into host machine, and copy it to Target Computer.
    ```shell
    docker cp container-id:/path/boot.img ~/Desktop/boot.img
    scp ~/Desktop/boot.img linaro@192.168.1.1:~/Downloads  # copy over to Target Computer
       
    # if your installation is on SD Card, we'll need to write this `boot.img` into `mmcblk1p4`:
    sudo dd if=boot.img of=/dev/mmcblk1p4 status=progress && sync 
   
    # if your installation is on Emmc, we'll need to write this `boot.img` into `mmcblk0p4`:
    sudo dd if=boot.img of=/dev/mmcblk0p4 status=progress && sync 
    ```
7. Restart your Target Computer with `sudo reboot`. It'll be able to launch with a patched kernel 4.19. 
8. Additional steps to show what to do next with `apparmor` as the example:
   ```shell
    # This step is for enabling of `apparmor` and other boot params.
    sudo vim /boot/cmdline.txt
    # cgroup_memory=1 cgroup_enable=memory cgroup_enable=cpuset
    apparmor=1 security=apparmor    
    systemd.unified_cgroup_hierarchy=1  # 1 = cgroupV2 , 0 = cgroupV1
    
    # check if i'm using cgroup v2 => stat -fc %T /sys/fs/cgroup/ OR cat /sys/fs/cgroup/cgroup.controllers
   ```

## Create new kernel 5.4.219 from kernel.org (WIP)
This is a Work-in-progress. welcome folks to try it out and add on to it!
```shell
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
git checkout
make clean && make distclean && make mrproper -j16
```

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
