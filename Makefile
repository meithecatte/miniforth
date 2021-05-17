boot.bin: boot.s
	yasm -f bin boot.s -o boot.bin

run: boot.bin
	qemu-system-i386 -curses -hda boot.bin
