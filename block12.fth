( improve : to allow referring to previous definition )
: link, ( -- ) here  latest @ ,  latest ! ;
: header, ( name len -- ) link, dup c, n, ;
: rel@ ( a -- v ) dup @ + cell+ ;
: rel! ( v a -- ) dup >r - 1 cells - r> ! ;
: rel, ( v -- ) here rel! 1 cells allot ;
latest @ >body 1+ rel@ constant 'docol
: call, e8 c, rel, ;
: hide latest @ cell+ dup >r c@ 40 or r> c! ;
: unhide latest @ cell+ dup >r c@ 40 invert and r> c! ;
: ; [ hide ] postpone exit postpone [ unhide ; immediate unhide
: : bl token header, 'docol call, hide ] ;
: recurse latest @ >body , ; immediate
: :noname ( -- xt ) s" " header, here 'docol call, hide ] ;

                                                             -->
