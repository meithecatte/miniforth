; Some newer BIOSes (read: UEFI back-compat modules) insist on a valid
; partition table in the MBR. We don't have enough free bytes to include
; that in the Miniforth seed. This file constitutes a shim, which presents
; a proper partition table to the BIOS and chainloads Miniforth (or any other
; tightly-golfed bootsector, for that matter).

    org 0x600

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov si, 0x7c00
    mov di, 0x600
    mov cx, 0x200
    cld
    rep movsb
    jmp 0:start
start:
; Both CHS and LBA code is present in the loader, as we have the free space
; and switching between the two manually is a single-byte edit.
%ifdef FLOPPY
    jmp load.chs
%else
    jmp load.lba
%endif

load:
.chs:
    mov ah, 0x02 ; function, chs load sector
    mov al, 1 ; count sectors

    mov dl, 0 ; drive (0 = floppy A:, 1 = floppy B:, 8 = HDD C:)
    mov dh, 0 ; head
    mov cl, 2 ; sector
    mov ch, 0 ; cylinder
    mov bx, 0x7c00 ; buffer
    int 0x13
    jc error.chs
    jmp 0x7c00
.lba:
    mov ah, 0x42 ; function, lba extended load
    mov si, lbapacket ; location of int13h/AH=42h arguments packet
    int 0x13
    jc error.lba
    jmp 0x7c00

error:
.lba:
    mov si, errmsg.lba
    jmp error.loop
.chs:
; TODO: some FDDs may be slow to start, and need to reset and reread
; the sector, while the disk spins up. Implement code here to do so
; three or four times, then go ahead and print the error message.
    mov si, errmsg.chs
    jmp error.loop
.loop:
; TODO: Read error numbers from BIOS return regs, and print them with errmsg.
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    xor bx, bx
    int 0x10
    jmp .loop
.done:
    hlt
    jmp .done

errmsg:
.lba:
    db "Forth: BIOS returns an LBA loader error.", 0
.chs:
    db "Forth: BIOS returns a CHS loader error.", 0

lbapacket:
    db 0x10
    db 0
    dw 1 ; count
    dw 0x7c00, 0 ; buffer
    dq 1 ; LBA

blank:
    times 446 - ($ - $$) db 0

mbrinfo:
    db 0 ; not active
    db 0, 1, 0 ; start CHS
    db 0x7f ; partition type (0x7f: experimental)
    db 0, 1, 0 ; end CHS
    dd 1 ; start LBA
    dd 1 ; length

    times 48 db 0
    db 0x55, 0xaa
