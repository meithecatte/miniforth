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

%define LINK 0

TIB equ 0x600
BLKBUF equ 0x700
BLKEND equ 0xb00
PACKET equ 0xb01
RS0 equ 0xc00

; header PLUS, "+"
; header COLON, ":", F_IMMEDIATE
%macro header 2-3 0
header_%1:
    dw LINK
%define LINK header_%1
%strlen namelength %2
    db %3 | namelength, %2
%1:
%endmacro

%macro defcode 2-3 0
    header %1, %2, %3
%endmacro

%macro defword 2-3 0
    header %1, %2, %3
    call DOCOL
%endmacro

    org 0x7c00

    jmp 0:start
start:
    xor ax, ax
    mov ds, ax
    ; TODO: wrap with CLI/STI if bytes are to spare (:doubt:)
    mov sp, 0x7bfe
    mov ss, ax
    mov bp, RS0
    mov [DRIVE_NUMBER], dl

; NOTE: we could extract EMIT into a CALL-able routine, but it's not worth it.
; A function called twice has an overhead of 7 bytes (2 CALLs and a RET), but the duplicated
; code is 6 bytes long.
; TODO: underflow protection, if we can afford it
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
    or bx, bx
    jz short REFILL
; during FIND,
; SI = dictionary pointer
; DX = string pointer
; BX = string length
FIND:
LATEST equ $+1
    mov si, LAST_LINK
.loop:
    push si
    mov cx, bx
    mov di, dx
    or si, si
    jz short NUMBER
    lodsw
    lodsb
    and al, F_HIDDEN | F_LENMASK
    cmp al, cl
    jne short .next
    repe cmpsb
    je short .found
.next:
    pop si
    mov si, [si]
    jmp short .loop
.found:
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
NUMBER:
    pop si
    mov si, dx
    xor bx, bx
    mov di, 10
.loop:
    mov ah, 0
    lodsb
    sub al, 0x30
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

defcode DISKLOAD, "load"
    mov di, BLKEND
    mov ax, 0x1000
    stosw
    mov ah, 2
    stosw
    stosb
    mov ah, BLKBUF >> 8
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
    push si
    mov si, PACKET
DRIVE_NUMBER equ $+1
    mov dl, 0
    mov ah, 0x42
    int 0x13
    pop si
    jc short jmpDROP
    mov word[TO_IN], BLKBUF
    jmp short jmpDROP

defcode PLUS, "+"
    pop ax
    add bx, ax
    jmp short NEXT

defcode MINUS, "-"
    pop ax
    sub ax, bx
    xchg bx, ax
    jmp short NEXT

defcode STORE, "!"
    pop word [bx]
jmpDROP:
    jmp short DROP

defcode LOAD, "@"
    mov bx, [bx]
    jmp short NEXT

defcode CSTORE, "c!"
    pop ax
    mov [bx], al
    jmp short DROP

defcode CLOAD, "c@"
    mov bl, [bx]
    mov bh, 0
    jmp short NEXT

defcode DUP, "dup"
    push bx
    jmp short NEXT

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

LIT:
    push bx
    lodsw
    xchg bx, ax
    jmp short NEXT

EXIT:
    dec bp
    dec bp
    mov si, [bp]
    jmp short NEXT

defcode DP, "dp"
    push bx
    mov bx, HERE
    jmp short NEXT

defcode WP, "wp"
    push bx
    mov bx, LATEST
    jmp short NEXT

defcode _STATE, "state"
    push bx
    mov al, [STATE]
    inc al
    ; ZF set if interpret
    mov bh, 0
    setz bl
    dec bx
    jmp short NEXT

DOCOL:
    mov [bp], si
    inc bp
    inc bp
    pop si
NEXT:
    lodsw
    jmp ax

defcode DROP, "drop"
    pop bx
    jmp short NEXT

defcode EMIT, "emit"
    xchg bx, ax
    xor bx, bx
    mov ah, 0x0e
    ; TODO: RBIL says some ancient BIOSes destroy BP. Save it on the stack if we
    ; can afford it.
    int 0x10
    jmp short DROP

defcode LBRACK, "[", F_IMMEDIATE
    mov byte[STATE], 0xff
    jmp short NEXT

defcode RBRACK, "]"
    mov byte[STATE], 0x80
    jmp short NEXT

defcode SWAP, "swap"
    pop ax
    push bx
    xchg ax, bx
    jmp short NEXT

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
    mov ax, [LATEST]
    mov di, [HERE]
    mov [LATEST], di
    stosw
    call _WORD
    lea ax, [bx + F_HIDDEN]
    stosb
    mov cx, bx
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

_COMMA:
HERE equ $+1
    mov di, 0x7e00
    stosw
    mov [HERE], di
    ret

; returns
; DX = pointer to string
; BX = string length
; clobbers SI
_WORD:
TO_IN equ $+1
    mov si, TIB
.skiploop:
    lodsb
    cmp al, 0x20
    je short .skiploop
    dec si
    mov dx, si
    xor bx, bx
.takeloop:
    inc bx
    lodsb
    or al, al
    jz short .done
    cmp al, 0x20
    jnz short .takeloop
.done:
    dec bx
    dec si
    mov [TO_IN], si
    ret

LAST_LINK equ LINK
    times 510 - ($ - $$) db 0
    db 0x55, 0xaa

    times 512 db 0
    incbin "test.fth"
    times 2048 - 6 - ($ - $$) db ' '
    db 'say-hi'
