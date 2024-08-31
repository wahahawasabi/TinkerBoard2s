FROM ubuntu:latest

ARG ubuntuNobleUrl="https://cdimage.ubuntu.com/ubuntu-base/releases/noble/release/ubuntu-base-24.04.1-base-arm64.tar.gz"
ARG workDirName="ubuntu-rootfs"

RUN apt-get update && apt-get upgrade -y \
    && apt-get -y install qemu-user-static curl \
    && mkdir /home/$workDirName \
    && curl -o /home/ubuntu.tar.gz $ubuntuNobleUrl \
    && tar -zvxf /home/ubuntu.tar.gz -C /home/$workDirName \
    && rm /home/ubuntu.tar.gz \
    && cp /usr/bin/qemu-aarch64-static /home/$workDirName/usr/bin/ \
    # for internet access. feel free to change this.
    && echo "nameserver 1.1.1.1" > /home/$workDirName/etc/resolv.conf \
    # recreating /devl/null so that chroot can perform `apt-get update` - rootfs default comes with "r" only but this needs to be changed to allow for updates to happen.
    && rm /home/$workDirName/dev/null \
    && mknod /home/$workDirName/dev/null c 1 3 \
    && chmod 666 /home/$workDirName/dev/null


WORKDIR /home/$workDirName/

COPY run* /home/
