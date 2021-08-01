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
    mov ah, 0x42
    mov si, packet
    int 0x13
    jc error
    jmp 0x7c00
packet:
    db 0x10
    db 0
    dw 1 ; count
    dw 0x7c00, 0 ; buffer
    dq 1 ; LBA

error:
    mov si, errmsg
.loop:
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
    db "Disk error :(", 0

    times 446 - ($ - $$) db 0

    db 0 ; not active
    db 0, 1, 0 ; start CHS
    db 0x42 ; type
    db 0, 1, 0 ; end CHS
    dd 1 ; start LBA
    dd 1 ; length

    times 48 db 0
    db 0x55, 0xaa
