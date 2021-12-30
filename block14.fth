( :noname recurse )
: link, ( list -- ) here swap  dup @ ,  ! ;
: header, ( name len -- ) latest link, dup c, n, ;
: rel@ ( a -- v ) dup @ + cell+ ;
: rel! ( v a -- ) dup >r - 1 cells - r> ! ;
: rel, ( v -- ) here rel! 1 cells allot ;
latest @ >xt 1+ rel@ constant 'docol
: call, E8 c, rel, ;
: hide latest @ cell+ dup >r c@ 40 or r> c! ;
: unhide latest @ cell+ dup >r c@ 40 invert and r> c! ;
: :noname ( -- xt ) s" " header, here 'docol call, hide ] ;
: recurse  latest @ >xt , ; immediate



                                                             -->
