# Guide

There are 2 scripts that we need to run to build the `rootfs`. First we need to copy `run-inside-chroot.sh` into `rootfs` folder, and give it `+x` permission. 
Then, once its execution is completed, we need to run `run-outside-chroot.sh` to generate the `.img` file.
```shell
cp run-inside-chroot.sh /home/ubuntu-rootfs
chroot ubuntu-rootfs /bin/bash
chmod +x run-inside-chroot.sh
ls # confirm that you are inside chroot and that run script is executable.

apt-get update
apt-get install vim
vim run-inside-chroot.sh 
# make modifications to the variables at the top and save it. 

./run-inside-chroot.sh
```
This is how we will generate the `sbin/init`, `fstab`, `networking` and other installation requirements. 

# kernelMods
Finally, we just need to untar `kernelMods.tar.gz` that we have extracted from `kernel boot` previously into  `lib/modules/<kernel-version-number>`.

# Final 2 steps
Once done, `cd..` and `run-outside-chroot.sh` to generate the rootfs.img. Copy it out of the docker container with `docker cp` and we can `dd` it into the sd card. 

Then we just need to boot it up, and log in. Then run `finalsteps.sh` to set up networking connectivity. Boomz, donezo. 


# optional steps (how to work with /boot/cmdline.txt)
to show what to do next with `apparmor` as the example:
```shell
 # This step is for enabling of `apparmor` and other boot params.
 sudo vim /boot/cmdline.txt
 apparmor=1 security=apparmor    
 systemd.unified_cgroup_hierarchy=1  # 1 = cgroupV2 , 0 = cgroupV1    
 # check if i'm using cgroup v2 => stat -fc %T /sys/fs/cgroup/ OR cat /sys/fs/cgroup/cgroup.controllers
```
