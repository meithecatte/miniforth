( assembler with more conventional syntax, targeting 16 and 32 bits )
vocabulary Assembler
Assembler definitions
variable 32bit  32bit off

: db ( b -- ) c, ; ( easily overrideable )
: dw ( u -- ) dup lobyte db hibyte db ;
: dd ( d. -- ) swap dw dw ;

( xt to be executed once all the operators are collected )
variable opcode  0 opcode !
variable want-opers
variable have-opers
( stores the ModR/M size the address prefix has chosen, if any )
variable what-modrm

0 cfield: oper.type
  cfield: oper.spec ( e.g. specific register )
  2field: oper.disp
  cfield: oper.wide-ignore
constant oper-size

( oper.type can contain: )
0 constant optype-imm
1 constant optype-r8
2 constant optype-r16
3 constant optype-r32
4 constant optype-[r16]
5 constant optype-[r32]
6 constant optype-[addr]
7 constant optype-cr
8 constant optype-sr

( stores the data width selected by the user with byte/word/dword )
variable instr-wide
( matches optype-r* for 1-3 )
0 constant wide-unk
1 constant wide8
2 constant wide16
3 constant wide32

: reset-asm ( -- )
  0 opcode !
  0 want-opers !
  0 instr-wide !
  0 what-modrm ! ;

: instr-done ( -- )
  opcode @ catch
  reset-asm
  throw ;
: instr-done? ( -- ) have-opers @ want-opers @ = if instr-done then ;

create opers  2 oper-size u* allot
: nth-oper ( u -- ptr ) oper-size u* opers + ;
: oper! ( disp. spec type u -- )
  >r
  r@ oper.type c!
  r@ oper.spec c!
  r@ oper.disp 2!
  0 r> oper.wide-ignore c! ;

: type@ ( oper# -- u ) nth-oper oper.type c@ ;
: spec@ ( oper# -- u ) nth-oper oper.spec c@ ;
: disp@ ( oper# -- u. ) nth-oper oper.disp 2@ ;
: wide-ignore ( oper# -- ) nth-oper oper.wide-ignore 1 swap c! ;

exception end-exception too-many-opers
: oper, ( disp. spec type -- )
  opcode @ 0= if ['] too-many-opers throw then
  have-opers @ want-opers @ >= if ['] too-many-opers throw then
  have-opers @ nth-oper oper!
  1 have-opers +!
  instr-done? ;

exception end-exception not-enough-opers
: previous-done ( -- )
  opcode @ if ['] not-enough-opers throw then ;

( "2 operand mov" )
: create-instr ( -- addr )
  create here 2 cells allot
 does> 2@ ( op xt )
  previous-done
  opcode ! want-opers !
  0 have-opers !
  instr-done? ;
: operand ( u -- ) create-instr
  :noname swap 2! ;

: v>d  all-dnums @ invert if s>d then ;
: v>ud all-dnums @ invert if 0 then ;
: .# ( imm. -- ) 0 optype-imm oper, ;
: # ( imm -- ) v>ud .# ;
: [.#] ( imm -- ) 0 optype-[addr] oper, ;
: [#] ( imm. -- ) v>ud [.#] ;
: reg: ( r t -- r t ) create 2, does> 2@ 0. 2swap oper, ;
: regs: ( r t n -- ) 0 ?do 2dup reg: >r 1+ r> loop 2drop ;
: disp: ( r t -- r t ) create 2, does> >r v>d r> 2@ oper, ;
: disps: ( r t n -- ) 0 ?do 2dup disp: >r 1+ r> loop 2drop ;

0 optype-r8  8 regs: al cl dl bl ah ch dh bh
0 optype-r16 8 regs: ax cx dx bx sp bp si di
0 optype-r32 8 regs: eax ecx edx ebx esp ebp esi edi

0 optype-[r16] 8 regs: [bx+si] [bx+di] [bp+si] [bp+di] [si] [di] [bp] [bx]
0 optype-[r32] 8 regs: [eax] [ecx] [edx] [ebx] [esp] [ebp] [esi] [edi]
0 optype-[r16] 4 disps: [bx+si+#] [bx+di+#] [bp+si+#] [bp+di+#]
4 optype-[r16] 4 disps: [si+#] [di+#] [bp+#] [bx+#]
0 optype-[r32] 4 disps: [eax+#] [ecx+#] [edx+#] [ebx+#]
4 optype-[r32] 4 disps: [esp+#] [ebp+#] [esi+#] [edi+#]
0 optype-cr reg: cr0 
2 optype-cr 3 regs: cr2 cr3 cr4
0 optype-sr 6 regs: es cs ss ds fs gs

: reg-op? ( nth -- t|f ) type@ optype-r8 optype-r32 1+ within ;
: mem-op? ( nth -- t|f ) type@ optype-[r16] optype-[addr] 1+ within ;

: reg@ ( nth -- r|-1 ) dup reg-op? if spec@ else drop -1 then ;

: prefix-datasize ( -- ) $66 db ;
: prefix-addrsize ( -- ) $67 db ;

( should the ModR/M be 32-bit? this is not the same as 32bit itself, )
( as the address size prefix overrides this )
: data16 ( -- ) 32bit @        if prefix-datasize then ;
: data32 ( -- ) 32bit @ invert if prefix-datasize then ;
: addr16 ( -- ) 1 what-modrm ! 32bit @        if prefix-addrsize then ;
: addr32 ( -- ) 2 what-modrm ! 32bit @ invert if prefix-addrsize then ;

( inferring the data width )
: op-wide ( nth -- u )
  dup nth-oper oper.wide-ignore c@ if
    drop wide-unk 
  exit then

  dup reg-op? if
    type@
  else
    drop wide-unk
  then ;

exception end-exception wideness-conflict
exception end-exception unknown-wideness

: wide-merge ( u u -- u )
  2dup = if drop ( in agreement ) else
  over 0= over 0= or if + ( one is unk ) else
  ['] wideness-conflict throw then then ;

: how-wide ( -- u )
  instr-wide @
  have-opers @ 0 ?do
    i op-wide wide-merge
  loop
  dup 0= if ['] unknown-wideness throw then ;

( for opcodes that distinguish byte/word width with bit 0 )
: op-wideflag ( op -- op' )
  how-wide case
    wide8  of           endof
    wide16 of 1+ data16 endof
    wide32 of 1+ data32 endof
  endcase ;

( user-facing operand size clarifiers )
: byte  wide8  instr-wide ! ;
: word  wide16 instr-wide ! ;
: dword wide32 instr-wide ! ;

( Mod R/M encoding )

( does a number fit within a signed immediate? )
: 32imm8? ( d. -- t|f ) case
    0 of   0 80 within endof
   -1 of -80 0  within endof
  2drop false  0 endcase ;
: 16imm8? ( d. -- t|f ) drop -80 80 within ;
: wimm8? ( d. wide8|16|32 -- t|f )
  case
    wide8  of 2drop true endof
    wide16 of 16imm8? endof
    wide32 of 32imm8? endof
  endcase ;

( emit the address size prefix based on a memory access operand )
: op-addr-size ( oper# -- )
  dup type@ case
    optype-[r16] of  drop addr16  endof
    optype-[r32] of  drop addr32  endof
    optype-[addr] of
      32bit @ if drop addr32 else
        disp@ nip 0= if addr16 else addr32 then
      then
    endof
  endcase ;

: mod-r/m-size ( oper# -- )
  dup mem-op? if op-addr-size else drop then ;

: modrm-byte ( oper# reg mode -- oper# )
  swap 3 lshift + over spec@ + db ;

: no-disp-16bit? ( oper# -- t|f )
  dup spec@ 6 ( [bp] ) <>
  swap disp@ d0= and ;

: no-disp-32bit? ( oper# -- t|f )
  dup spec@ 5 ( [ebp] ) <>
  swap disp@ d0= and ;

: sib? ( oper# -- oper# )
  dup spec@ 4 ( [esp] ) = if $24 db then ;

exception end-exception bad-operands
: or-bad-operands ( t|f -- ) invert ['] bad-operands and throw ;

: oper-reg-16bit ( oper# reg -- )
  over type@ case
    optype-[r16] of
      over no-disp-16bit? if
        0 modrm-byte drop
      else
        over disp@ 16imm8? if
          ( 8-bit displacement )
          $40 modrm-byte
          nth-oper oper.disp c@ db
        else
          ( 16-bit displacement )
          $80 modrm-byte
          nth-oper oper.disp @ dw
        then
      then
    endof
    optype-[addr] of
      3 lshift $06 + db
      nth-oper oper.disp @ dw
    endof
    ['] bad-operands throw
  endcase ;
: oper-reg-32bit ( oper# reg -- )
  over type@ case
    optype-[r32] of
      over no-disp-32bit? if
        0 modrm-byte sib? drop
      else
        over disp@ 32imm8? if
          ( 8-bit displacement )
          $40 modrm-byte sib?
          nth-oper oper.disp c@ db
        else
          ( 32-bit displacement )
          $80 modrm-byte sib?
          disp@ dd
        then
      then
    endof
    optype-[addr] of
      3 lshift $05 + db
      disp@ dd
    endof
    ['] bad-operands throw
  endcase ;
: oper-reg ( oper# reg -- )
  over reg-op? if
    3 lshift swap spec@ + $c0 + db
  else
    what-modrm @ case
      1 of oper-reg-16bit endof
      2 of oper-reg-32bit endof
      cr ." what-modrm not set "
    endcase
  then ;

( opcode with dirflag in bit 1 and modrm )
: op-dir-modrm ( op -- )
  1 reg-op? if
    0 mod-r/m-size
    db 0 1 spec@ oper-reg
  else
    1 mem-op? if 2 +
      0 reg-op? or-bad-operands
      1 mod-r/m-size
      db 1 0 spec@ oper-reg
    then
  then ;

: imm, ( oper# -- )
  disp@
  how-wide case
    wide8  of d>s db endof
    wide16 of d>s dw endof
    wide32 of     dd endof
  endcase ;

: byte|wide ( byte wide -- byte|wide )
  how-wide case
    wide8  of drop endof
    wide16 of nip  data16 endof
    wide32 of nip  data32 endof
  endcase ;

: must-wide ( -- )
  how-wide case
    wide8  of ['] bad-operands throw endof
    wide16 of data16 endof
    wide32 of data32 endof
  endcase ;

: reg-offset ( regop base -- )
  over reg-op? or-bad-operands
  swap spec@ + db ;

0 operand lodsb  $AC db ;
0 operand lodsw  data16 $AD db ;
0 operand lodsd  data32 $AD db ;
0 operand cli  $FA db ;
0 operand sti  $FB db ;
0 operand retf $CB db ;
1 operand lgdt  0 mem-op? or-bad-operands
  0 mod-r/m-size  $0F db $01 db 0 2 oper-reg ;
1 operand jmp   must-wide  0 mod-r/m-size  $FF db 0 4 oper-reg ;
1 operand push  must-wide  0 $50 reg-offset ;
1 operand pop   must-wide  0 $58 reg-offset ;
2 operand jmpf
  0 type@ optype-imm = or-bad-operands
  1 type@ optype-imm = or-bad-operands
  EA db
  32bit @ if
    1 disp@ dd
  else
    1 disp@ d>s dw
  then
  0 disp@ d>s dw ;

2 operand mov
  1 type@ optype-imm = if
    0 reg-op? if
      ( mov reg, imm )
      0  $B0 $B8 byte|wide reg-offset
      1 imm,
    else
      0 mem-op? or-bad-operands
      ( mov mem, imm )
      0 mod-r/m-size
      $C6 op-wideflag db
      0 0 oper-reg
      1 imm,
    then
  else
    0 type@ optype-r32 = 1 type@ optype-cr = and if
      $0F db $20 db 0 1 spec@ oper-reg
    exit then

    0 type@ optype-cr = 1 type@ optype-r32 = and if
      $0F db $22 db 1 0 spec@ oper-reg
    exit then

    1 type@ optype-sr = if
      must-wide 0 mod-r/m-size
      $8C db 0 1 spec@ oper-reg
    exit then

    0 type@ optype-sr = if
      must-wide 1 mod-r/m-size
      $8E db 1 0 spec@ oper-reg
    exit then

    $88 op-wideflag op-dir-modrm
  then ;

: aluop
  1 type@ optype-imm = if
    0 reg-op? 0 spec@ 0= and if
      ( op al/ax/eax, imm )
      3 lshift $04 + op-wideflag db
      1 imm,
    else
      0 mod-r/m-size
      1 disp@ how-wide wimm8? if
        $80 $83 byte|wide db
        0 swap oper-reg
        1 nth-oper oper.disp c@ db
      else
        $80 op-wideflag db
        0 swap oper-reg
        1 imm,
      then
    then
  else
    3 lshift op-wideflag op-dir-modrm
  then ;

2 operand add  0 aluop ;
2 operand or   1 aluop ;
2 operand adc  2 aluop ;
2 operand sbb  3 aluop ;
2 operand and  4 aluop ;
2 operand sub  5 aluop ;
2 operand xor  6 aluop ;
2 operand cmp  7 aluop ;

: shiftop
  0 mod-r/m-size
  1 wide-ignore
  1 type@ optype-imm = if
    1 disp@ 1. d= if
      $D0 op-wideflag db
      0 swap oper-reg
    else
      $C0 op-wideflag db
      0 swap oper-reg
      1 nth-oper oper.disp c@ db
    then
  else
    1 type@ optype-r8 = or-bad-operands
    1 spec@ 1 = ( cl ) or-bad-operands
    $D2 op-wideflag db
    0 swap oper-reg
  then ;

2 operand rol  0 shiftop ;
2 operand ror  1 shiftop ;
2 operand rcl  2 shiftop ;
2 operand rcr  3 shiftop ;
2 operand shl  4 shiftop ;
2 operand shr  5 shiftop ;
2 operand sar  7 shiftop ;

( I/O instructions )
( encoding: $E4 [1110d1ow] )
( w - wide )
( o - out / otherwise in )
( d - dx / as opposed to imm )

: i/o-op ( port-oper base val-oper )
  dup reg@ 0= or-bad-operands ( val can only be al/ax/eax )
  type@ case
    optype-r16 of 1+ data16 endof
    optype-r32 of 1+ data32 endof
    ( otherwise optype-r8, which doesn't need anything )
  endcase ( port-oper base )
  over type@ case
    optype-r16 of
      swap spec@ 2 = ( dx ) or-bad-operands
      8 + db
    endof
    optype-imm of
      db disp@ d>s db
    endof
    ['] bad-operands throw
  endcase ;

2 operand in  1 $E4 0 i/o-op ;
2 operand out 0 $E6 1 i/o-op ;

: ;code ( -- )
  32bit @ if
    lodsd
    jmp eax
  else
    lodsw
    jmp ax
  then
  previous ;
Forth definitions
: :code ( -- ) :code Assembler ;
previous definitions

previous definitions
