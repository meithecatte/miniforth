; Register usage:
; SP = parameter stack pointer (grows downwards from 0x7c00 - just before the entrypoint)
; BP = return stack pointer (grows upwards from 0x500 - just after BDA)
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

TIB equ 0x600
BLKBUF equ 0x700
BLKEND equ 0xb00
LATEST equ 0xb12 ; dw
TO_IN  equ 0xb14 ; dw
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
    xor ax, ax
    mov ds, ax
    mov es, ax
    ; TODO: wrap with CLI/STI if bytes are to spare (:doubt:)
    mov sp, 0x7c00
    mov ss, ax
    mov bp, RS0

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
    mov di, TIB
    mov [TO_IN], di
.loop:
    mov ah, 0
    int 0x16
    cmp al, 0x0d
    je short .enter
    cmp al, 0x08
    jne short .write
    mov cx, di
    or cl, cl
    jz short .loop
    dec di
    db 0xb1 ; skip the dec di below by loading its opcode to CL
.write:
    stosb
    mov ah, 0x0e
    xor bx, bx
    int 0x10
    jmp short .loop
.enter:
    xor ax, ax
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

NUMBER:
    mov si, dx
    xor bx, bx
BASE equ $+1
    mov di, 16
.loop:
    mov ah, 0
    lodsb
    or al, 0x20 ; to lowercase
    sub al, "0"
    cmp al, 9
    jbe .digit_ok
    sub al, "a" - "0" - 10
.digit_ok
    xchg ax, bx
    mul di
    add bx, ax
    loop .loop
    cmp byte[STATE], 0x80
    je short COMPILE_LIT
    push bx
    jmp short INTERPRET
COMPILE_LIT:
    mov ax, LIT
    call _COMMA
    xchg ax, bx
    call _COMMA
    jmp short INTERPRET

Found:
    xchg ax, si
    pop si
    test byte[si+2], 0xff
STATE equ $-1 ; 0xff -> interpret, 0x80 -> compile
    jnz short EXECUTE
    call _COMMA
    jmp short INTERPRET
EXECUTE:
    pop bx
    mov si, .return
    jmp ax
.return:
    dw .executed
.executed:
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
; clobbers SI
_WORD:
    mov si, [TO_IN]
    ; repe scasb would probably save some bytes if the registers worked out - scasb
    ; uses DI instead of SI :(
.skiploop:
    lodsb
    cmp al, " "
    je short .skiploop
    dec si
    mov dx, si
    xor cx, cx
.takeloop:
    inc cx
    lodsb
    or al, al
    jz short .done
    cmp al, " "
    jnz short .takeloop
.done:
    dec cx
    dec si
    mov [TO_IN], si
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
    dw BLKBUF
    ; rest is zeroed out at runtime, overwriting the compressed data, which is no longer
    ; necessary

CompressedData:
    times COMPRESSED_SIZE db 0xcc

; Invariant: due to the use of compression_sentinel without a dictionary header following it,
; the first byte of LIT and EXIT must have the 0x40 (F_HIDDEN) bit set.

DOCOL:
    mov [bp], si
    inc bp
    inc bp
    pop si
CompressedBegin:
    compression_sentinel

LIT:
    push bx
    lodsw
    xchg bx, ax
    compression_sentinel

EXIT:
    dec bp
    dec bp
    mov si, [bp]

defcode DISKLOAD, "load"
    push si
    mov si, DiskPacket
    lea di, [si+6]
    xor ax, ax
    stosw
    shl bx, 1
    xchg ax, bx
    stosw
    xchg ax, bx
    stosw
    stosw
    stosw
    mov [BLKEND], al
DRIVE_NUMBER equ $+1
    mov dl, 0
    mov ah, 0x42
    int 0x13
    pop si
    jc short .done
    mov word[TO_IN], BLKBUF
.done:
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

defcode _STATE, "st"
    push bx
    xor bx, bx
    mov al, [STATE]
    inc al
    jz short .interpret
    dec bx
.interpret:

defcode DROP, "drop"
    pop bx

defcode EMIT, "emit"
    xchg bx, ax
    xor bx, bx
    mov ah, 0x0e
    ; TODO: RBIL says some ancient BIOSes destroy BP. Save it on the stack if we
    ; can afford it.
    int 0x10
    pop bx

defcode SWAP, "swap"
    pop ax
    push bx
    xchg ax, bx

defcode TO_R, ">r"
    mov [bp], bx
    inc bp
    inc bp
    pop bx

defcode FROM_R, "r>"
    dec bp
    dec bp
    push bx
    mov bx, [bp]

defcode LBRACK, "[", F_IMMEDIATE
    mov byte[STATE], 0xff

defcode RBRACK, "]"
    mov byte[STATE], 0x80

; defword COLON takes 6 more bytes than defcode COLON
; (the defword is untested and requires some unwritten primitives)
; defword COLON, ":"
;     dw _HERE
;     dw _LATEST, LOAD, COMMA
;     dw _LATEST, STORE
;     dw __WORD, DUP, LIT, F_HIDDEN, PLUS, CCOMMA
;     dw _HERE, SWAP, CMOVE
;     dw LIT, 0xe8, CCOMMA
;     dw LIT, DOCOL-2, HERE, MINUS, COMMA
;     dw RBRACK, EXIT
defcode COLON, ":"
    push bx
    push si
    mov di, [HERE]
    call MakeLink
    call _WORD
    mov ax, cx
    or al, F_HIDDEN
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
    mov [HERE], di
    jmp short RBRACK

defcode SEMI, ";", F_IMMEDIATE
    mov di, [LATEST]
    and byte[di+2], ~F_HIDDEN
    mov ax, EXIT
    call _COMMA
    jmp short LBRACK
; INVARIANT: last word in compressed block does not rely on having NEXT appended by
; decompressor
CompressedEnd:

COMPRESSED_SIZE equ CompressedEnd - CompressedBegin - savings
