boot.bin: boot.s compress.py test.fth
	yasm -f bin boot.s -o raw.bin -l boot.lst
	python3 compress.py

run: boot.bin
	qemu-system-i386 -curses -hda boot.bin

test: boot.bin
	qemu-system-i386 -curses -hda test.img
