: pop, 58 + c, ;
: movb-ir, b0 + c, c, ;
: int, cd c, c, ;
: movw-ir, b8 + c, , ;
create packet 10 allot
:code int13
si push,
packet si movw-ir,
bx ax movw-rr,
disk# dl movb-ir,
13 int,
ax bx movw-rr,
si pop,
next,
variable pos
: pos, pos @ ! 2 pos +! ;
: make-packet packet pos ! 10 pos, 2 pos, pos, 0 pos, 2* pos, 0 pos, 0 pos, 0 pos, ;
: read-block make-packet 4200 int13 ;
: write-block make-packet 4302 int13 ;
: cr 0D emit 0A emit ;
: incw, 40 + c, ;
: decw, 48 + c, ;
: addw-rr, 03 c, rm-r, ;
: orw-rr, 0b c, rm-r, ;
: andw-rr, 23 c, rm-r, ;
: subw-rr, 2b c, rm-r, ;
: xorw-rr, 33 c, rm-r, ;
: cmpw-rr, 3b c, rm-r, ;
: jb, 72 c, ; : jc, 72 c, ; : jae, 73 c, ; : jnc, 73 c, ;
: jz, 74 c, ; : jnz, 75 c, ; : jbe, 76 c, ; : ja, 77 c, ;
: jl, 7c c, ; : jge, 7d c, ; : jle, 7e c, ; : jg, 7f c, ;
: j> here 0 c, ;
: >j dup >r 1 + here swap - r> c! ;
: j< here ;
: <j here 1 + - c, ;
: p dup c@ u. 1 + ;
: :cmp :code ax ax xorw-rr, ;
: cmp; j> ax decw, >j ax bx movw-rr, next, ;
:cmp 0= bx bx orw-rr, jnz, cmp;
