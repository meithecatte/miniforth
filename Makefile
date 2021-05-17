boot.bin: boot.s
	yasm -f bin boot.s -o boot.bin -l boot.lst
	grep 'times 510' boot.lst | awk '{print $$2}'

run: boot.bin
	qemu-system-i386 -curses -hda boot.bin
