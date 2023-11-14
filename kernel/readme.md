This document shows the steps required to patch kernel. 

It is required for the Tinker Engineers to provide the `dtb` files before we can proceed. until date, they have `dtb` for 4.4, 4.19, and 5.10 (tbc)

- linaro gcc tested successfully:
    - [6.3-2017.05](https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/)
    - [6.4-2017.11](https://releases.linaro.org/components/toolchain/binaries/6.4-2017.11/aarch64-linux-gnu/)
    - [6.5-2018.12](https://releases.linaro.org/components/toolchain/binaries/6.5-2018.12/aarch64-linux-gnu/)
    - [7.5.0-2019](https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/) (we'll be using this in the `dockerfile`)
          
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
          # IPRoute Settings
          CONFIG_SCSI_NETLINK=y
          CONFIG_NET_SCHED=y
          CONFIG_IP_MULTIPLE_TABLES=y
          
          # IP config to try out
          CONFIG_IP_NF_CONNTRACK=m
          CONFIG_IP_NF_FTP=m
          CONFIG_IP_NF_MATCH_LIMIT=m
          CONFIG_IP_NF_MATCH_MAC=m
          CONFIG_IP_NF_MATCH_MARK=m
          CONFIG_IP_NF_MATCH_MULTIPORT=m
          CONFIG_IP_NF_MATCH_TOS=m
          CONFIG_IP_NF_MATCH_TCPMSS=m
          CONFIG_IP_NF_MATCH_STATE=m
          CONFIG_IP_NF_MATCH_UNCLEAN=m
          CONFIG_IP_NF_MATCH_OWNER=m
          CONFIG_IP_NF_TARGET_LOG=m
          CONFIG_IP_NF_TARGET_TCPMSS=m
          CONFIG_IP_NF_COMPAT_IPCHAINS=m
          CONFIG_IP_NF_COMPAT_IPFWADM=m
          CONFIG_BRIDGE_NETFILTER=m
          
          
          # Calico IP Set Configs
          CONFIG_IP_SET=y
          CONFIG_IP_SET_MAX=256
          CONFIG_IP_SET_BITMAP_IP=y
          CONFIG_IP_SET_BITMAP_IPMAC=y
          CONFIG_IP_SET_BITMAP_PORT=y
          CONFIG_IP_SET_HASH_IP=y
          CONFIG_IP_SET_HASH_IPMARK=y
          CONFIG_IP_SET_HASH_IPPORT=y
          CONFIG_IP_SET_HASH_IPPORTIP=y
          CONFIG_IP_SET_HASH_IPPORTNET=y
          CONFIG_IP_SET_HASH_IPMAC=y
          CONFIG_IP_SET_HASH_MAC=y
          CONFIG_IP_SET_HASH_NETPORTNET=y
          CONFIG_IP_SET_HASH_NET=y
          CONFIG_IP_SET_HASH_NETNET=y
          CONFIG_IP_SET_HASH_NETPORT=y
          CONFIG_IP_SET_HASH_NETIFACE=y
          CONFIG_IP_SET_LIST_SET=y
          
          
          # BPF Configs
          CONFIG_BPF=y
          CONFIG_CGROUP_BPF=y
          CONFIG_BPF_SYSCALL=y
          CONFIG_BPF_JIT=y
          CONFIG_NET_CLS_BPF=y
          CONFIG_NET_CLS_ACT=y
          CONFIG_NET_SCH_INGRESS=y
          CONFIG_CRYPTO_SHA1=y
          CONFIG_BPF_EVENTS=y
          CONFIG_HAVE_EBPF_JIT=y
          CONFIG_UPROBE_EVENTS=y
          CONFIG_KPROBE_EVENTS=y
      
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
          CONFIG_SMP=y        
          # Additional Configs for Cgroupv2
          # CONFIG_HUGETLB is not avalible on arm devices. 
          # CONFIG_PROC_PID_CPUSET=y  # CONFIG_CPUSETS=y  # seems like these 2 are already set 
          # tinker2 only has support for cgroupv1... to check with later kernels.
          
          # Additional Configs for NFS
          CONFIG_NFS_FS=m
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
   
   make modules_install INSTALL_MOD_PATH=/home/tinkeros/kernel/MODULES/
   tar czf name_of_archive_file.tar.gz name_of_directory_to_tar
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