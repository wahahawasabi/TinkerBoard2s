FROM ubuntu:latest

# Example: web folder = 6.3-2017.05 , tar file = 6.3.1-2017.05
ARG gccVersion=6.3
ARG gccSubVersion=1
ARG gccYear=2017
ARG gccBuild=05

ARG gccFolder="$gccVersion-$gccYear.$gccBuild"
ARG gccTarFile="$gccVersion.$gccSubVersion-$gccYear.$gccBuild"

RUN apt-get update && apt-get upgrade -y && \
    # Install required libs
    apt-get install -y ca-certificates procps curl vim xz-utils git wget \
    bison flex make bc build-essential libncurses-dev libssl-dev libelf-dev liblz4-tool \
    python-is-python3 && \
    # get the gcc  \
    wget https://releases.linaro.org/components/toolchain/binaries/"$gccFolder"/aarch64-linux-gnu/gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz --directory /home/tinkeros/ &&\
    # Setup gcc
    tar -xvf /home/tinkeros/gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz --directory /home/tinkeros/ &&\
    rm /home/tinkeros/gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz &&\
    # git clone https://github.com/TinkerBoard2/kernel.git /home/tinkeros/kernel/ --progress \
    git clone https://github.com/TinkerBoard-Linux/rockchip-linux-kernel.git /home/tinkeros/kernel/ --progress

# adding gcc to path
ENV PATH="${PATH}:/home/tinkeros/gcc-linaro-$gccVersion-x86_64_aarch64-linux-gnu/bin"

########### References ###########
# https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/
# Note: https://tinker-board.asus.com/forum/index.php?/topic/14988-kernel-build-error-lz4c/