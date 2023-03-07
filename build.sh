#!/bin/sh -e
mkdir -p build
yasm -f bin boot.s -o build/raw.bin -l build/boot.lst
yasm -f bin uefix.s -o build/uefix.bin
python3 scripts/compress.py
python3 scripts/mkdisk.py
