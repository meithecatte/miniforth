#!/bin/sh -e
yasm -f bin boot.s -o raw.bin -l boot.lst
yasm -f bin uefix.s -o uefix.bin
python3 scripts/compress.py
python3 scripts/mkdisk.py
