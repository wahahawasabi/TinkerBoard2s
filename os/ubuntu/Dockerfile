FROM ubuntu:latest

ARG ubuntuNobleUrl="https://cdimage.ubuntu.com/ubuntu-base/releases/noble/release/ubuntu-base-24.04.1-base-arm64.tar.gz"
ARG workDirName="bunturootfs"

COPY run* /home/

RUN apt-get update && apt-get upgrade -y \
    && apt-get -y install qemu-user-static curl vim \
    && mkdir /home/$workDirName \
    && curl -o /home/ubuntu.tar.gz $ubuntuNobleUrl \
    && tar -zvxf /home/ubuntu.tar.gz -C /home/$workDirName \
    && cp /usr/bin/qemu-aarch64-static /home/$workDirName/usr/bin/ \
    && chmod +x /home/run*

WORKDIR /home/
