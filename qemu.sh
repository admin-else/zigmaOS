#!/bin/sh
./mkiso.sh || exit 1
qemu-system-i386 -cdrom zigma.iso