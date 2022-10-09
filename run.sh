#!/bin/sh
qemu-system-i386 -display curses -enable-kvm -hda ${1:-miniforth.img}
