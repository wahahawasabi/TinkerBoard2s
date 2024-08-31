# Introduction

This repo serves as a guide on how to create your own bootable images to be used on your Tinker Board.

Currently, this has been tested successfully on:
- Tinker Board 2
- Tinker Board 2s

Each of the sections also contains a `Dockerfile` which comes prepacked with all the required libraries for building. 

# contents
These are the steps that we will be taking to rebuild the linux os.

1. [Partition creation](boot/partitions.md)
   - partitions guide
2. [Building images](boot/bootImages.md)
   - uboot.img & trust.img
     - changing of rootfs (important, else linux os won't be able to load)
   - idbloader.img
   - kernel.img 
   - Writing boot images to media card
     - sd card
     - emmc
3. [Building OS image (3 examples)](os/osReadme.md)
   - [ubuntu](os/ubuntu/ubuntuGuide.md)
   - fedora
   - alpine