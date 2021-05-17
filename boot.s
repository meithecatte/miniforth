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

%define F_IMMEDIATE 0x80
%define F_HIDDEN    0x40
%define F_LENMASK   0x1f

%define LINK 0

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
    mov ss, ax
    mov sp, 0x7c00

    mov bp, 0x600
    mov di, 0x7e00
    call DOCOL
    dw LIT, 3
    dw DOUBLE

    dw LIT, '0'
    dw PLUS
    dw EMIT
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
    halt
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

defword DOUBLE, "DOUBLE"
    dw DUP, PLUS, EXIT

    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
