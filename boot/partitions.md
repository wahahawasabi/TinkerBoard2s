# Partition format to follow
| Partition No. | Name      | Sector Start | Sector End | Size  | Comments                 |
|---------------|-----------|--------------|------------|-------|--------------------------|
| -             | idbloader | 64           | 16383      |       | first stage boot loader  |
| 1             | uboot     | 16384        | 24575      | 4mb   | second stage boot loader |
| 2             | trust     | 24576        | 32767      | 4mb   | linux / android trust    |
| 3             | misc      | 32768        | 40959      | 4mb   | for misc inputs          |
| 4             | boot      | 40960        | 172031     | 64mb  | linux kernel boot        |
| 5             | userdata  | 172032       | 303103     | 64mb  | for kernel boot elements |
| 6             | rootfs    | 303104       | ~          | ~     | core linux OS            |

You can make further reference [here](https://github.com/TinkerBoard-Linux/rockchip-linux-device-rockchip/blob/linux5.10-rk3399-debian11/.chips/rk3399/parameter-tinkerboard2.txt).
You will need to convert hexadecimals to sectors. ChatGPT will be a good friend in this aspect. Just ask it how to convert this location sectors from hexadecimals to sectors.

The important thing to follow is for `idbloader`, `uboot`, `trust`, `kernel`. This is because the `bootrom` code from TinkerBoard will directly look into these sectors
to load the respective `bootloaders`. As for `userdata` and `rootfs`, this can be defined directly in the `uboot` code based on partition number.
(seen later in [bootImages.md](../boot/bootImages.md) file).

# Create partitions

Let's use `parted` to create the respective partitions based on the above table (note: this is on Linux. You can do something similar in windows using disk management.):
```shell
sudo parted -s /dev/sdb mklabel gpt
# idbloader does not need a partition. In line with what Asus engineers are doing. 
sudo parted /dev/sdb unit s mkpart uboot 16384 24575 
sudo parted /dev/sdb unit s mkpart trust 24576 32767
sudo parted /dev/sdb unit s mkpart misc 32768 40959
sudo parted /dev/sdb unit s mkpart boot 40960 172031
sudo parted /dev/sdb unit s mkpart userdata ext2 172032 303103 
sudo parted /dev/sdb unit s mkpart rootfs ext4 303104 16777182  # you can extend this later within the os itself with gparted.
sudo mkfs.ext2 /dev/sdb5
sudo mkfs.ext4 /dev/sdb6

sudo parted /dev/sdb print
lsblk -f
````

## References:
1. [Asus forum - partition build](https://tinker-board.asus.com/forum/index.php?/topic/15552-unable-to-boot-into-rootfs-after-building-uboot-and-kernel-from-source/&tab=comments#comment-17335)
