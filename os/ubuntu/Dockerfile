FROM ubuntu:latest

ARG ubuntuNobleUrl="https://cdimage.ubuntu.com/ubuntu-base/releases/noble/release/ubuntu-base-24.04.1-base-arm64.tar.gz"
ARG workDirName="ubuntu-rootfs"

COPY run* /home/

RUN apt-get update && apt-get upgrade -y \
    && apt-get -y install qemu-user-static curl vim \
    && mkdir /home/$workDirName \
    && curl -o /home/ubuntu.tar.gz $ubuntuNobleUrl \
    && tar -zvxf /home/ubuntu.tar.gz -C /home/$workDirName \
    && rm /home/ubuntu.tar.gz \
    && cp /usr/bin/qemu-aarch64-static /home/$workDirName/usr/bin/ \
    # for internet access. feel free to change this.
    && echo "nameserver 1.1.1.1" > /home/$workDirName/etc/resolv.conf \
    # creating /devl/null so that chroot can perform `apt-get update`
    && mknod /home/$workDirName/dev/null c 1 3 \
    && chmod 666 /home/$workDirName/dev/null \
    && chmod +x /home/run*

WORKDIR /home/
