( stack manipulation )
: nip ( ab--b) swap drop ;  : tuck ( ab--bab) swap over ;
: rot ( abc--bca) >r swap r> swap ;  : -rot rot rot ;
:code 2swap ( c d a b -- a b c d )
  ax pop, dx pop, cx pop,
  ax push, bx push, cx push, dx bx movw-rr, next,
:code 1- bx decw, next,         : cell- 2 - ;
: literal lit, ; immediate      : negate  0 swap - ;
: within ( n lo hi -- f|t ) over - >r - r> u< ;
: s8? ( n -- f|t ) FF80 80 within ;
: +m-r, ( off m r -- ) 3shl + over s8? if 40 + c, c, else
  80 + c, , then ;      : +r-m, ( off r m -- ) swap +m-r, ;
: movw+mr, 8B c, +m-r, ;        : movw+rm, 89 c, +r-m, ;
: rpick: ( off -- ) 1+ cells negate :code
  bx push, [di] bx movw+mr, next, ;
0 rpick: r@     1 rpick: rover  2 rpick: 2rpick              -->
