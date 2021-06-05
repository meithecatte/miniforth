; Register usage:
; SP = parameter stack pointer (grows downwards from 0x7c00 - just before the entrypoint)
; DI = return stack pointer (grows upwards from 0xc00)
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
stack:
    dw HERE
    dw BASE
    dw STATE
    dw LATEST
start:
    cli
    push cs
    push cs
    push cs
    pop ds
    pop es
    pop ss
    mov sp, stack
    sti
    cld

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
    push dx ; for FORTH code

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
    jcxz short REFILL
; during FIND,
; SI = dictionary pointer
; DX = string pointer
; BX = string length
FIND:
    push bx ; save the numeric value in case the word is not found in the dictionary
    mov bx, cx
LATEST equ $+1
    mov si, 0
.loop:
    mov cx, bx
    mov di, dx
    lodsw
    push ax ; save pointer to next entry
    lodsb
    xor al, cl ; if the length matches, then AL contains only the flags
    test al, F_HIDDEN | F_LENMASK
    jnz short .next
    repe cmpsb
    je short Found
.next:
    pop si
    or si, si
    jnz short .loop

; it's a number
    cmp byte[STATE], 0xeb
    je short INTERPRET ; already pushed at the beginning of FIND
; we're compiling
    mov ax, LIT
    call _COMMA
    pop ax
    jmp short Compile

; When we get here, SI points to the code of the word, and AL contains
; the F_IMMEDIATE flag
Found:
    pop bx ; discard pointer to next entry
    pop bx ; discard numeric value
    or al, al
    xchg ax, si
STATE equ $ ; 0xeb (jmp) -> interpret, 0x75 (jnz) -> compile
    jmp short EXECUTE
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
.takeloop:
    lodsb
    and al, ~0x20 ; to uppercase, but also integrate null check and space check
    jz short .done
    inc cx
    sub al, 0x10
    cmp al, 9
    jbe .digit_ok
    sub al, "A" - 0x10 - 10
.digit_ok
    cbw
    ; imul bx, bx, <BASE> but yasm insists on encoding the immediate in just one byte...
    db 0x69, 0xdb
BASE equ $
    dw 16
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
    movzx bx, byte[bx]

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
    push " " - "0"
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

defcode LBRACK, "[", F_IMMEDIATE
    mov byte[STATE], 0xeb

defcode RBRACK, "]"
    mov byte[STATE], 0x75

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
