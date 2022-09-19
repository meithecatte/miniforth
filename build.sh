#!/bin/sh
yasm -f bin boot.s -o raw.bin -l boot.lst
yasm -f bin uefix.s -o uefix.bin
python3 compress.py
python3 mkdisk.py
