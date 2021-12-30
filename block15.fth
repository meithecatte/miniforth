( defer )
exception  str defer-vector:  end-exception unset-defer
: bad-defer ( nt -- ) >name defer-vector: 2!
  ['] unset-defer throw ;
: defer  : latest @ postpone{ literal bad-defer ; } ;
E9 constant jmp16
: defer! ( target-xt defer-xt ) jmp16 over c! 1+ rel! ;
: defer@ ( xt -- xt' ) dup c@ jmp16 = if 1+ rel@ then ;
: is ( xt -- ) ' defer! ;
exception  str word:  end-exception unknown-word
:noname 2dup word: 2! find
  dup 0= ['] unknown-word and throw ; is must-find
:noname #bl token header, 'docol call, ; is create:
: : create: hide ] ;
: ; postpone{ exit [ } unhide ; unhide immediate
                                                             -->
