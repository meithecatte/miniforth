( halt during key )
: hlt, F4 c, ;                  :code halt hlt, next,
:code waitkey j< hlt, 1 ah movb-ir, 16 int, jz, <j next,
:code key' bx push, ax ax xorw-rr, 16 int, ax bx movw-rr, next,
:noname  waitkey key' ; is key










                                                             -->
