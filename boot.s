; Register usage:
; SP = parameter stack pointer (grows downwards from 0x7c00 - just before the entrypoint)
; BP = return stack pointer (grows upwards from 0x500 - just after BDA)
; SI = execution pointer
; DI = compilation pointer (HERE)
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

TIB equ 0x7e00
NTIB equ 0x7f00 ; db
STATE equ 0x7f01

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
    mov sp, 0x7c00
    mov ss, ax

    mov bp, 0x600
    mov di, 0x7e00
    call DOCOL
    dw REFILL
.wordloop:
    dw _WORD
    dw DUP
    dw LIT, '0', PLUS, EMIT
    dw ZBRANCH, .done
    dw DROP
    dw BRANCH, .wordloop

.done:
    dw HALT

defcode PLUS, "+"
    pop ax
    add bx, ax
    jmp short NEXT

defcode MINUS, "-"
    pop ax
    sub ax, bx
    xchg bx, ax
    jmp short NEXT

defcode HALT, "HALT"
    hlt
    jmp short HALT

defcode EMIT, "EMIT"
    xchg bx, ax
    xor bx, bx
    mov ah, 0x0e
    ; TODO: RBIL says some ancient BIOSes destroy BP. Save it on the stack if we
    ; can afford it.
    int 0x10
    pop bx
    jmp short NEXT

defcode DUP, "DUP"
    push bx
    jmp short NEXT

defcode DROP, "DROP"
    pop bx
    jmp short NEXT

ZBRANCH:
    lodsw
    or bx, bx
    pop bx
    jnz short NEXT
    db 0xb1 ; skip the lodsw below by loading its opcode to CL

BRANCH:
    lodsw
    xchg si, ax
    jmp short NEXT

LIT:
    push bx
    lodsw
    xchg bx, ax
    jmp short NEXT

DOCOL:
    mov [bp], si
    inc bp
    inc bp
    pop si
NEXT:
    lodsw
    jmp ax

EXIT:
    dec bp
    dec bp
    mov si, [bp]
    jmp short NEXT

; NOTE: we could extract EMIT into a CALL-able routine, but it's not worth it.
; A function called twice has an overhead of 7 bytes (2 CALLs and a RET), but the duplicated
; code is 6 bytes long.
; TODO: underflow protection
defcode REFILL, "REFILL"
    push di
    push bx
    mov di, TIB
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
    mov [TO_IN], al
    pop bx
    pop di
    jmp short NEXT

defcode _WORD, "WORD"
    push bx
    mov dx, si
TO_IN equ $+1
    mov si, TIB
.skiploop:
    lodsb
    cmp al, 0x20
    je short .skiploop
    dec si
    push si
    xor bx, bx
.takeloop:
    inc bx
    lodsb
    or al, al
    jz short .done
    cmp al, 0x20
    jnz .takeloop
.done:
    dec bx
    dec si
    xchg ax, si
    mov [TO_IN], al
    mov si, dx
    jmp short NEXT

    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
