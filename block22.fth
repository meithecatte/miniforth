( division )
: divw-r,  F7 c, 6 rm-r, ;
:code (um/mod) dx pop, ax pop, bx divw-r,
  dx push, ax bx movw-rr, next,
exception end-exception division-by-zero
exception end-exception division-overflow
: um/mod ( ud u -- mod quot )
  dup 0= ['] division-by-zero and throw
  2dup >= ['] division-overflow and throw  (um/mod) ;
: u/mod ( u u -- mod quot ) 0 swap um/mod ;
: ud/mod ( ud u -- mod dquot )
  tuck u/mod >r ( lo div hi R: hi-res )
  swap um/mod r> ;


                                                             -->
