#!/usr/bin/env bash

debootstrap --arch arm64 --foreign jammy /home/workspace/  # foreign is when you are doing the bootstrap from a different architecture machine
cp /usr/bin/qemu-aarch64-static /workspace/usr/bin/  # this is required to virtualize this installation in the next step.
chroot /workspace /usr/bin/qemu-aarch64-static /bin/bash -i  # enter into this installation as a root user
debootstrap --second-stage  # this is only available / needed when --foreign is used (takes about 5-7 minutes)

