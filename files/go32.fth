( switch to protected mode )
( see also: Intel SDM Volume 3A,                )
( Section 10.9.1. "Switching to Protected Mode" )
s" asm32.fth" require Assembler

ds@ 0= #-12 and >in +! alter-0-only

( this address happens to be safe so :p         )
$A20 constant victim
victim $10 + constant farvictim

( returns true if A20 is unlocked. possible false negative if the two )
( memory locations happen to have the same value by chance )
: (a20?) ( -- t|f )
  0 fs!         victim farc@
  $ffff fs!  farvictim farc@ <> ;

: frob-victim ( -- )
  0 fs!  victim farc@  55 xor  victim farc! ;
: a20? ( -- t|f )
  (a20?) if true else
    frob-victim (a20?) frob-victim
  then ;

( I'll bother implementing actual unlocking when I find a machine )
( that needs it ;3 )
exception end-exception a20-locked
: a20 ( -- ) a20? invert ['] a20-locked and throw ;

:code cli  cli ;code
:code sti  sti ;code

( port I/O )
:code pc@
  mov dx bx
  in al dx
  mov ah 0 #
  mov bx ax
;code

:code pc!
  mov dx bx
  pop ax
  out dx al
  pop bx
;code

( NMIs )
: nmi-on  $70 pc@ $7f and $70 pc!  $71 pc@ drop ;
: nmi-off $70 pc@ $80 or  $70 pc!  $71 pc@ drop ;

( GDT )
: entries 8 u* ;
create gdt 3 entries allot

variable access
$80 constant PRESENT
$10 constant ~SPECIAL ( this bit is 0 in some shit like TSS )
$08 constant EXECUTABLE
$02 constant R/W

variable flags
$80 constant GRANULARITY
$40 constant 32BIT

: entry ( selector "name" -- )
  dup constant $FFF8 and
  gdt + pos !
  $FFFF pos, ( limit low )
  0 pos,     ( base low )
  access @ 8 lshift pos, ( low 8 bits is base )
  flags @ $F or     pos, ( high 8 bits is base; low 4 is limit ) ;

GRANULARITY 32BIT or flags !
PRESENT ~SPECIAL or R/W or EXECUTABLE or access !
8 entry 32bit-cs

PRESENT ~SPECIAL or R/W or access !
10 entry 32bit-ds

( GDTR )
gdt pos !
3 entries 1- pos, ( size )
gdt pos, 0 pos, ( address )

:code lgdt
  lgdt gdt [#]
;code

( one-time setup )
lgdt
a20

( pmode transition )
:code pmode-entry
  32bit on
  mov eax 32bit-ds #
  mov ds eax
  mov es eax
  mov ss eax
  mov byte $B8000. [.#] 2 #
  EB db FE db
  32bit off
;code

:code (go32)
  mov eax cr0
  or al 1 #
  mov cr0 eax
  jmpf 32bit-cs # ' pmode-entry #
;code

: go32 ( -- ) cli nmi-off (go32) ;
