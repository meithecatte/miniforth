; Register usage:
; SP = parameter stack pointer (grows downwards from 0x7c00 - just before the entrypoint)
; DI = return stack pointer (grows upwards from 0x500 - just after BDA)
; SI = execution pointer
; BX = top of stack
;
; Dictionary structure:
; link: dw
; name: counted string (with flags)
;
; The Forth is DTC, as this saves 2 bytes for each defcode, while costing 3 bytes
; for each defword.

F_IMMEDIATE equ 0x80
F_HIDDEN    equ 0x40
F_LENMASK   equ 0x1f

InputBuf equ 0x600
BlockBuf equ 0x700
BlockBuf.end equ 0xb00
LATEST equ 0xb02 ; dw
InputPtr  equ 0xb04 ; dw
RS0 equ 0xc00

SPECIAL_BYTE equ 0x90

%assign savings 0

%macro compression_sentinel 0
%assign savings savings+4
    db SPECIAL_BYTE
    dd 0xdeadbeef
%endmacro

; defcode PLUS, "+"
; defcode COLON, ":", F_IMMEDIATE
%macro defcode 2-3 0
    compression_sentinel
%strlen namelength %2
    db %3 | namelength, %2
%1:
%endmacro

    org 0x7c00

    jmp 0:start
start:
    cli
    push cs
    push cs
    push cs
    pop ds
    pop es
    pop ss
    mov sp, 0x7c00
    sti
    cld

    push word STATE
    push word BASE
    push word HERE

    mov si, CompressedData
    mov di, CompressedBegin
    mov cx, COMPRESSED_SIZE
.decompress:
    lodsb
    cmp al, SPECIAL_BYTE
    jnz short .not_special
    mov ax, 0xffad ; lodsw / jmp ax
    stosw
    mov al, 0xe0
    stosb
    call MakeLink
    db 0xb1
.not_special:
    stosb
    loop .decompress

    mov [DRIVE_NUMBER], dl

; NOTE: we could extract EMIT into a CALL-able routine, but it's not worth it.
; A function called twice has an overhead of 7 bytes (2 CALLs and a RET), but the duplicated
; code is 6 bytes long.
REFILL:
    xor bx, bx ; for int 0x10
    mov di, InputBuf
    mov [InputPtr], di
.loop:
    mov ah, 0
    int 0x16
    cmp al, 0x0d
    je short .enter
    cmp al, 0x08
    jne short .write
    cmp di, InputBuf
    je short .loop
    dec di
    db 0xb1 ; skip the dec di below by loading its opcode to CL
.write:
    stosb
    mov ah, 0x0e
    int 0x10
    jmp short .loop
.enter:
    xchg ax, bx
    stosb
INTERPRET:
    call _WORD
    or cx, cx
    jz short REFILL
; during FIND,
; SI = dictionary pointer
; DX = string pointer
; BX = string length
FIND:
    push bx ; save the numeric value in case the word is not found in the dictionary
    mov bx, cx
    mov si, [LATEST]
.loop:
    push si
    mov cx, bx
    mov di, dx
    lodsw
    lodsb
    and al, F_HIDDEN | F_LENMASK
    cmp al, cl
    jne short .next
    repe cmpsb
    je short Found
.next:
    pop si
    mov si, [si]
    or si, si
    jnz short .loop

; it's a number
    cmp byte[STATE], 0x80
    jne short INTERPRET ; already pushed at the beginning of FIND
; we're compiling
    mov ax, LIT
    call _COMMA
    pop ax
    jmp short Compile

Found:
    xchg ax, si
    pop si ; get dictionary pointer back
    pop bx ; discard numeric value
    test byte[si+2], 0xff
STATE equ $-1 ; 0xff -> interpret, 0x80 -> compile
    jnz short EXECUTE
Compile:
    call _COMMA
    jmp short INTERPRET
EXECUTE:
RetSP equ $+1
    mov di, RS0
    pop bx
    mov si, .return
    jmp ax
.return:
    dw .executed
.executed:
    mov [RetSP], di
    push bx
    jmp short INTERPRET

;ZBRANCH:
;    lodsw
;    or bx, bx
;    pop bx
;    jnz short NEXT
;    db 0xb1 ; skip the lodsw below by loading its opcode to CL
;
;BRANCH:
;    lodsw
;    xchg si, ax
;    jmp short NEXT

_COMMA:
HERE equ $+1
    mov [CompressedEnd], ax
    add word[HERE], 2
    ret

; returns
; DX = pointer to string
; CX = string length
; BX = numeric value
; clobbers SI and BP
_WORD:
    mov si, [InputPtr]
    ; repe scasb would probably save some bytes if the registers worked out - scasb
    ; uses DI instead of SI :(
.skiploop:
    lodsb
    cmp al, " "
    je short .skiploop
    dec si
    push si
    xor cx, cx
    xor bx, bx
BASE equ $+1
    mov bp, 16
.takeloop:
    lodsb
    or al, 0x20 ; to lowercase, but also integrate null check and space check
    cmp al, " "
    jz short .done
    inc cx
    mov ah, 0
    sub al, "0"
    cmp al, 9
    jbe .digit_ok
    sub al, "a" - "0" - 10
.digit_ok
    xchg ax, bx
    mul bp
    add bx, ax
    jmp short .takeloop
.done:
    dec si
    mov [InputPtr], si
    pop dx
    ret

MakeLink:
    mov ax, [LATEST]
    mov [LATEST], di
    stosw
    ret

DiskPacket:
    db 0x10, 0
.count:
    dw 2
.buffer:
    ; rest is zeroed out at runtime, overwriting the compressed data, which is no longer
    ; necessary

CompressedData:
    times COMPRESSED_SIZE db 0xcc

; Invariant: due to the use of compression_sentinel without a dictionary header following it,
; the first byte of LIT and EXIT must have the 0x40 (F_HIDDEN) bit set.

DOCOL:
    xchg ax, si
    stosw
    pop si
CompressedBegin:
    compression_sentinel

LIT:
    push bx
    lodsw
    xchg bx, ax
    compression_sentinel

EXIT:
    dec di
    dec di
    mov si, [di]

defcode DISKLOAD, "load"
    pusha
.retry:
    mov si, DiskPacket
    lea di, [si+4]
    mov ax, BlockBuf
    mov [InputPtr], ax
    stosw
    xor ax, ax
    stosw
    shl bx, 1
    xchg ax, bx
    stosw
    xchg ax, bx
    stosw
    stosw
    stosw
    mov [BlockBuf.end], al
DRIVE_NUMBER equ $+1
    mov dl, 0
    mov ah, 0x42
    int 0x13
    jc short .retry
    popa
    pop bx

defcode PLUS, "+"
    pop ax
    add bx, ax

defcode MINUS, "-"
    pop ax
    sub ax, bx
    xchg bx, ax

defcode STORE, "!"
    pop word [bx]
    pop bx

defcode LOAD, "@"
    mov bx, [bx]

defcode CSTORE, "c!"
    pop ax
    mov [bx], al
    pop bx

defcode CLOAD, "c@"
    mov bl, [bx]
    mov bh, 0

defcode DUP, "dup"
    push bx

defcode DROP, "drop"
    pop bx

defcode EMIT, "emit"
    xchg bx, ax
    mov cx, 1
    jmp short UDOT.got_digit

defcode UDOT, "u."
    xor cx, cx
    xchg ax, bx
    push word " " - "0"
    inc cx
.split:
    xor dx, dx
    div word[BASE]
    push dx
    inc cx
    or ax, ax
    jnz .split
.print:
    pop ax
    add al, "0"
    cmp al, "9"
    jbe .got_digit
    add al, "A" - "0" - 10
.got_digit:
    xor bx, bx
    mov ah, 0x0e
    int 0x10
    loop .print
    pop bx

defcode SWAP, "swap"
    pop ax
    push bx
    xchg ax, bx

defcode TO_R, ">r"
    xchg ax, bx
    stosw
    pop bx

defcode FROM_R, "r>"
    dec di
    dec di
    push bx
    mov bx, [di]

defcode LBRACK, "[", F_IMMEDIATE
    mov byte[STATE], 0xff

defcode RBRACK, "]"
    mov byte[STATE], 0x80

defcode COLON, ":"
    push bx
    push si
    xchg di, [HERE]
    call MakeLink
    call _WORD
    mov ax, cx
    stosb
    mov si, dx
    rep movsb
    mov al, 0xe8 ; call
    stosb
    mov ax, DOCOL-2
    sub ax, di
    stosw
    pop si
    pop bx
    xchg [HERE], di
    jmp short RBRACK

defcode SEMI, ";", F_IMMEDIATE
    mov ax, EXIT
    call _COMMA
    jmp short LBRACK
; INVARIANT: last word in compressed block does not rely on having NEXT appended by
; decompressor
CompressedEnd:

COMPRESSED_SIZE equ CompressedEnd - CompressedBegin - savings
