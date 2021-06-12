#!/bin/sh
qemu-system-i386 -curses -hda ${1:-disk.img}
