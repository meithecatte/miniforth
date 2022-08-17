( numeric output )
: decimal #10 base ! ;          : hex #16 base ! ;
: ud. ( ud -- ) <# #s #> type space ;
: d. ( d -- ) dup 0< if [char] - emit dnegate then ud. ;
:noname 0 ud. ; is u.           : .  s>d d. ;
: spaces ( u -- ) begin dup while 1- space repeat drop ;
: type.r ( str n -- ) 2dup < if over - spaces else drop then
  type ;
: u.r ( u w -- ) >r 0 <# #s #> r> type.r ;
: .r ( n w -- ) over 0>= if u.r else >r negate
  0 <# #s [char] - hold #> r> type.r then ;
: hex. ( u -- ) ." $" base @ swap hex u. base ! ;
: depth.  ." <" depth 0 u.r ." > " ;
: .s depth. depth begin dup while dup pick . 1- repeat drop ;
: u.s depth. depth begin dup while dup pick u. 1- repeat drop ;
: ?  @ dup . hex. ;                                          -->
