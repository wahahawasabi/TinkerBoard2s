# Introduction

This repo serves as a guide on how to create your own bootable images to be used on your Tinker Board.

Currently, this has been tested successfully on:
- Tinker Board 2
- Tinker Board 2s

The guide is broken down into 2 sections with detailed explanation along the way:
- [Boot](boot/bootImages.md)
  - uboot
  - kernel
- Linux OS (format will be similar to load other Linux variations)
  - Ubuntu
  - Alpine
  - Fedora Core OS

Each of the sections also contains a `Dockerfile` which contains all the required libraries for building. 

# contents
These are the steps that we will be taking to rebuild the linux os.

1. Partition creation
   - placeholder
2. Building images
   - uboot.img & trust.img
     - changing of rootfs (important, else linux os won't be able to load)
   - idbloader.img
   - kernel.img
3. Writing boot images to media card
   - sd card
   - emmc
4. Building OS image
5. Writing to media card
   - sd card
   - emmc
