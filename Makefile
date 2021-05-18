boot.bin: boot.s
	yasm -f bin boot.s -o boot.bin -l boot.lst
	@echo $$((0x`grep 'times 510' boot.lst | awk '{print $$2}'`)) bytes used

run: boot.bin
	qemu-system-i386 -curses -hda boot.bin
