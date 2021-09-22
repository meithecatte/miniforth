( stack manipulation )
: nip ( a b -- b ) swap drop ;
: tuck ( a b -- b a b ) swap over ;
:code 2swap ( c d a b -- a b c d )
  ax pop, dx pop, cx pop,
  ax push, bx push, cx push, dx bx movw-rr, next,
:code 1- bx decw, next,
: literal lit, ; immediate
: cell- 2 - ;






                                                             -->
