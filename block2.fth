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
: make-packet packet pos ! 10 pos, 2 pos, pos, 0 pos, dbl pos, 0 pos, 0 pos, 0 pos, ;
: read-block make-packet 4200 int13 ;
: write-block make-packet 4302 int13 ;
