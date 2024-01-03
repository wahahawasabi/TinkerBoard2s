FROM ubuntu:jammy

WORKDIR /home

COPY entrypoint.sh .

# Toolchain
ARG gccVersion=7.5
ARG gccSubVersion=0
ARG gccYear=2019
ARG gccBuild=12
ARG gccFolder="$gccVersion-$gccYear.$gccBuild"
ARG gccTarFile="$gccVersion.$gccSubVersion-$gccYear.$gccBuild"

# git information
ARG asusRkLinuxUboot="https://github.com/TinkerBoard-Linux/rockchip-linux-u-boot.git"
ARG currentBranch="linux5.10-rk3399-debian11"

RUN apt-get update && apt-get upgrade -y && \
    apt-get -y install git wget bc build-essential && \
    # get the gcc  \
    wget https://releases.linaro.org/components/toolchain/binaries/"$gccFolder"/aarch64-linux-gnu/gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz &&\
    # Setup gcc
    tar -xvf gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz && \
    rm gcc-linaro-"$gccTarFile"-x86_64_aarch64-linux-gnu.tar.xz && \
    # clone TinkerBoard 2 repository
    git clone $asusRkLinuxUboot ./source --progress && \
    cd source && \
    git checkout $currentBranch

# adding gcc to path
ENV PATH="${PATH}:/home/gcc-linaro-$gccVersion-x86_64_aarch64-linux-gnu/bin"