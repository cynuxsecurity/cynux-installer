#!/bin/bash

CHROOT=/mnt
chroot $CHROOT "/bin/bash" <<EOF
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-key
EOF
