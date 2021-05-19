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
RS0 equ 0x700

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

; NOTE: we could extract EMIT into a CALL-able routine, but it's not worth it.
; A function called twice has an overhead of 7 bytes (2 CALLs and a RET), but the duplicated
; code is 6 bytes long.
; TODO: underflow protection, if we can afford it
REFILL:
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

defcode PLUS, "+"
    pop ax
    add bx, ax
    jmp short NEXT

defcode MINUS, "-"
    pop ax
    sub ax, bx
    xchg bx, ax
    jmp short NEXT

defcode DUP, "dup"
    push bx
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

defcode CCOMMA, "c,"
    xchg ax, bx
    mov di, [HERE]
    stosb
    mov [HERE], di
    jmp short DROP

defcode _HERE, "here"
    push bx
    mov bx, [HERE]
    jmp short NEXT

defcode ALLOT, "allot"
    add [HERE], bx
    jmp short DROP

defcode EMIT, "emit"
    xchg bx, ax
    xor bx, bx
    mov ah, 0x0e
    ; TODO: RBIL says some ancient BIOSes destroy BP. Save it on the stack if we
    ; can afford it.
    int 0x10
    jmp short DROP

defcode DROP, "drop"
    pop bx
    jmp short NEXT

defcode LBRACK, "[", F_IMMEDIATE
    mov byte[STATE], 0xff
    jmp short NEXT

defcode RBRACK, "]"
    mov byte[STATE], 0x80
    jmp short NEXT

; TODO: this might be smaller as a defword
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
    mov al, 0xe8
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
    mov byte[STATE], 0xff
    push bx
    mov bx, EXIT
    jmp short COMMA

defcode COMMA, ","
    xchg ax, bx
    call _COMMA
    jmp short DROP

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
    xchg ax, si
    mov [TO_IN], al
    ret

LAST_LINK equ LINK
    times 510 - ($ - $$) db 0
    db 0x55, 0xaa
