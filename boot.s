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
; for each defword (of which there are none in the bootsector)
;
; Memory layout:
; 0000 - 03ff  IVT
; 0400 - 04ff  Reserved by BIOS
; 0500 - 05ff  Keyboard input buffer
; 0600 - 09ff  Disk block buffer (for LOAD)
; 0a00 - 0aff  Assorted variables (only 3 bytes are actually used at the moment)
; 0b00 - ...   Return stack (grows upwards)
; ...  - ...   Space for manual allocation by user
; ...  -~7c10  Parameter stack
; 7c00 - 7dff  MBR (code loaded by BIOS)
; 7e00 - ...   Decompressed code and dictionary space (HERE / ALLOT)

F_IMMEDIATE equ 0x80
F_HIDDEN    equ 0x40
F_LENMASK   equ 0x1f

InputBuf equ 0x500
BlockBuf equ 0x600
BlockBuf.end equ 0xa00
InputPtr  equ 0xa02 ; dw
RS0 equ 0xb00

SPECIAL_BYTE equ 0xff

%assign savings 0

%macro compression_sentinel 0
%assign savings savings+4
    db SPECIAL_BYTE
    dd 0xdeadbeef
%endmacro

; defcode PLUS, "+"
; defcode SEMI, ";", F_IMMEDIATE
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
    push cs
    push cs
    push cs
    pop ds
    pop es
    ; Little known fact: writing to SS disables interrupts for the next instruction,
    ; so this is safe without an explicit cli/sti.
    pop ss
    mov sp, stack
    cld

    mov si, CompressedData
    mov di, CompressedBegin
    mov cx, COMPRESSED_SIZE
.decompress:
    lodsb
    stosb
    cmp al, SPECIAL_BYTE
    jnz short .not_special

    mov byte [di-1], 0xad ; lodsw
    ; since SPECIAL_BYTE, we only need to load half of FF E0 jmp ax
    mov ah, 0xe0
    stosw
    call MakeLink
.not_special:
    loop .decompress

    ; di = CompressedEnd here
    mov [di + DRIVE_NUMBER - CompressedEnd], dl
    push dx ; for FORTH code

%ifdef AUTOLOAD
    push 1
    mov ax, LOAD
    jmp InterpreterLoop.execute
%endif

ReadLine:
    mov di, InputBuf
    mov [InputPtr], di
.loop:
    mov ah, 0
    int 0x16
    cmp al, 0x08
    jne short .write
    cmp di, InputBuf ; underflow check
    je short .loop
    dec di
    db 0x3c          ; mask next instruction
.write:
    stosb
    call PutChar
    cmp al, 0x0d
    jne short .loop
.enter:
    mov al, 0x0a
    int 0x10
    mov [di-1], bl ; write the null terminator by using the BX = 0 from PutChar
InterpreterLoop:
    call ParseWord
    jcxz short ReadLine

; Try to find the word in the dictionary.
; SI = dictionary pointer
; DX = string pointer
; CX = string length
; Take care to preserve BX, which holds the numeric value.
LATEST equ $+1
    mov si, 0
.find:
    lodsw
    push ax ; save pointer to next entry
    lodsb
    xor al, cl ; if the length matches, then AL contains only the flags
    test al, F_HIDDEN | F_LENMASK
    jnz short .next
    mov di, dx
    push cx
    repe cmpsb
    pop cx
    je short .found
.next:
    pop si
    or si, si
    jnz short .find

    ; It's a number. Push its value - we'll pop it later if it turns out we need to compile
    ; it instead.
    push bx
    ; At this point, AH is zero, since it contains the higher half of the pointer
    ; to the next word, which we know is NULL.
    cmp byte[STATE], ah
    jnz short InterpreterLoop
    ; Otherwise, compile the literal.
    mov ax, LIT
    call COMMA
    pop ax
.compile:
    call COMMA
    jmp short InterpreterLoop

.found:
    pop bx ; discard pointer to next entry
    ; When we get here, SI points to the code of the word, and AL contains
    ; the F_IMMEDIATE flag
STATE equ $+1
    or al, 1
    xchg ax, si ; both codepaths need the pointer to be in AX
    jz short .compile

    ; Execute the word
.execute:
    mov di, RS0
    pop bx
    mov si, .return
    jmp ax
.return:
    dw .executed
.executed:
    push bx
    jmp short InterpreterLoop

COMMA:
HERE equ $+1
    mov [CompressedEnd], ax
    add word[HERE], 2
Return:
    ret

; returns
; DX = pointer to string
; CX = string length
; BX = numeric value
; clobbers SI
ParseWord:
    mov si, [InputPtr]
    ; repe scasb would probably save some bytes here if the registers worked out - scasb
    ; uses DI instead of SI :(
.skiploop:
    mov dx, si ; if we exit the loop in this iteration, dx will point to the first letter
               ; of the word
    lodsb
    cmp al, " "
    je short .skiploop
    xor cx, cx
    xor bx, bx
.takeloop:
    ; AL is already loaded by the end of the previous iteration, or the previous loop
    and al, ~0x20 ; to uppercase, but also integrate null check and space check
    jz short Return
    inc cx
    sub al, "0" &~0x20
    cmp al, 9
    jbe .digit_ok
    sub al, "A" - ("0" &~0x20) - 10
.digit_ok
    cbw
    ; imul bx, bx, <BASE> but yasm insists on encoding the immediate in just one byte...
    db 0x69, 0xdb
BASE equ $
    dw 16
    add bx, ax
    mov [InputPtr], si
    lodsb
    jmp short .takeloop

; Creates a dictionary linked list link at DI.
MakeLink:
    mov ax, di
    xchg [LATEST], ax  ; AX now points at the old entry, while
                       ; LATEST and DI point at the new one.
    stosw
    ret

PutChar:
    xor bx, bx
    mov ah, 0x0e
    int 0x10
    ret

DiskPacket:
    db 0x10, 0
.count:
    dw 2
.buffer:
    ; rest is filled out at runtime, overwriting the compressed data,
    ; which isn't necessary anymore

CompressedData:
    times COMPRESSED_SIZE db 0xcc

; Invariant: due to the use of compression_sentinel without a dictionary header following it,
; the first byte of LIT and EXIT must have the 0x40 (F_HIDDEN) bit set.

CompressedBegin:

DOCOL:
    xchg ax, si
    stosw
    pop si ; grab the pointer pushed by `call`
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

defcode PEEK, "@" ; ( addr -- val )
    mov bx, [bx]

defcode POKE, "!" ; ( val addr -- )
    pop word [bx]
    pop bx

defcode CPEEK, "c@" ; ( addr -- ch )
    movzx bx, byte[bx]

defcode CPOKE, "c!" ; ( ch addr -- )
    pop ax
    mov [bx], al
    pop bx

defcode DUP, "dup" ; ( a -- a a )
    push bx

defcode DROP, "drop" ; ( a -- )
    pop bx

defcode SWAP, "swap" ; ( a b -- b a )
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

defcode EMIT, "emit"
    xchg bx, ax
    call PutChar
    pop bx

defcode UDOT, "u."
    xchg ax, bx
    ; the hexdigit conversion algo below turns 0x89 into a space.
    ; 0x89 itself doesn't fit in a signed 8-bit immediate that
    ; a two-byte instruction uses, but we don't care about the
    ; high 8 bits of the value
    ; this expression tricks yasm into emitting this without
    ; a warning
    push byte -((-0x89) & 0xff)
.split:
    xor dx, dx
    div word[BASE]
    push dx
    or ax, ax
    jnz .split
.print:
    pop ax

    add al, 0x90
    daa
    adc al, 0x40
    daa

    call PutChar
    cmp al, " "
    jne short .print
    pop bx

defcode LOAD, "load"
    pusha
    mov di, DiskPacket.buffer
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
    mov si, DiskPacket
    int 0x13
    jc short $
    popa
    pop bx

;; Copies the rest of the line to buf.
defcode LINE, "s:" ; ( buf -- buf+len )
    xchg si, [InputPtr]
.copy:
    lodsb
    mov [bx], al
    inc bx
    or al, al
    jnz short .copy
.done:
    dec bx
    dec si
    xchg si, [InputPtr]

defcode LBRACK, "[", F_IMMEDIATE
    inc byte[STATE]

defcode RBRACK, "]"
    dec byte[STATE]

defcode COLON, ":"
    pusha
    mov di, [HERE]
    call MakeLink
    call ParseWord
    mov ax, cx
    stosb
    mov si, dx
    rep movsb

    mov al, 0xe8 ; call
    stosb
    ; The offset is defined as (call target) - (ip after the call instruction)
    ; That works out to DOCOL - (di + 2) = DOCOL - 2 - di
    mov ax, DOCOL - 2
    sub ax, di
    stosw
    mov [HERE], di
    popa
    jmp short RBRACK

defcode SEMI, ";", F_IMMEDIATE
    mov ax, EXIT
    call COMMA
    jmp short LBRACK
; INVARIANT: last word in compressed block does not rely on having NEXT appended by
; decompressor
CompressedEnd:

COMPRESSED_SIZE equ CompressedEnd - CompressedBegin - savings
