FROM ubuntu:latest

# Example: web folder = 6.3-2017.05 , tar file = 6.3.1-2017.05
ARG gccVersion=6.3
ARG gccSubVersion=1
ARG gccYear=2017
ARG gccBuild=05

ARG gccFolder="$gccVersion-$gccYear.$gccBuild"
ARG gccTarFile="$gccVersion.$gccSubVersion-$gccYear.$gccBuild"

ARG kernel510="https://github.com/TinkerBoard-Linux/"

WORKDIR /home/tk

RUN apt-get update && apt-get upgrade -y && \
    # Install required libs
    apt-get install -y ca-certificates procps curl vim xz-utils git wget kmod gawk \
    bison flex make bc build-essential libncurses-dev libssl-dev libelf-dev liblz4-tool \
    python-is-python3 && \
    # get the gcc  \
    wget https://releases.linaro.org/components/toolchain/binaries/"$gccFolder"/aarch64-linux-gnu/gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz --directory /home/tk/ &&\
    # Setup gcc
    tar -xvf /home/tk/gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz --directory /home/tk/ &&\
    rm /home/tk/gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz &&\
    # clone all the required libraries from TinkerBoard-5.10 github
    git clone $kernel510/rockchip-linux-kernel.git /home/tk/kernel --progress  && \
    git clone $kernel510/rockchip-linux-u-boot /home/tk/uboot --progress  && \
    git clone $kernel510/rockchip-linux-rkbin /home/tk/rkbin --progress && \
    git clone $kernel510/rockchip-linux-device-rockchip /home/tk/rockchipDevice --progress

# adding gcc to path
ENV PATH="${PATH}:/home/tk/gcc-linaro-$gccTarFile-x86_64_aarch64-linux-gnu/bin"

########### References ###########
# gcc version to use: https://tinker-board.asus.com/forum/index.php?/topic/14989-u-boot-build-error-tinkerboard-2s/
# gcc libaries: https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/
# lz4c error issue: https://tinker-board.asus.com/forum/index.php?/topic/14988-kernel-build-error-lz4c/
# stronum never defined issue:
