( double-cell values, stored little endian - ANS be damned )
: s>d dup 0< ;  : d>s drop ;
: 2@ dup @ swap cell+ @ ;       : 2! swap over cell+ ! ! ;
: 2literal swap lit, lit, ; immediate
: 2variable create 2 cells allot ;
: 2constant : [[ swap lit, lit, 'exit , ;
: 2>r compile >r compile >r ; immediate
: 2r> compile r> compile r> ; immediate
: mulw-r,  F7 c, 4 rm-r, ;      : adcw-rr,  13 c, rm-r, ;
:code um* ( u u -- ud )
  ax pop, bx mulw-r,  ax push, dx bx movw-rr,  next,
: u*  um* d>s ;
:code d+  ax pop, dx pop, cx pop,
  cx ax addw-rr,  dx bx adcw-rr,  ax push, next,
: ud*u ( ud u -- ud ) tuck u* >r um* r> + ;
: dnegate invert swap invert swap 1 0 d+ ;                   -->
