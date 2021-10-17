( colored output )
:code emit-tty bx ax movw-rr, 0E ah movb-ir, bx bx xorw-rr,
  10 int, bx pop, next,
:code curpos@ bx push, bx bx xorw-rr, 3 ah movb-ir, 10 int,
  dx bx movw-rr, next,
:code curpos! bx dx movw-rr, 2 ah movb-ir, bx bx xorw-rr,
  10 int, bx pop, next,

create color 7 ,
: fs> 64 c, ; :code fs! 8E c, bx 4 rm-r, bx pop, next,
:code +fs!  ax pop, fs> al [bx] movb-rm, bx pop, next,
: vga! B800 fs! +fs! ;
: attr! ( attr curpos -- ) dup hibyte #80 u* swap lobyte +
  2* 1+ vga! ;
:noname ( c -- ) curpos@ over emit-tty swap printable? if
  color @ swap attr! else drop then ; is emit
                                                             -->
