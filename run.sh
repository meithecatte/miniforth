#!/bin/sh
qemu-system-i386 -curses -enable-kvm -hda ${1:-disk.img}
