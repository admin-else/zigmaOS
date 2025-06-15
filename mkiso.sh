#!/bin/sh
set -xe
zig build
mkdir -p isodir/boot/grub         
cp zig-out/bin/kernel.elf isodir/boot/kernel.elf
cp grub.cfg isodir/boot/grub/grub.cfg
grub2-mkrescue -o zigma.iso isodir