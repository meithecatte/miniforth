( dictionary lookup )
: search-in ( name len first-nt -- nt|0 )
begin dup while >r
2dup r@ header-name s= if
2drop r> exit then
r> @ repeat >r 2drop r> ;
: find latest @ search-in ;
: >body ( nt -- xt ) cell+ dup c@ lenmask and + 1+ ;
: immediate? ( nt -- t|f ) cell+ c@ 80 and 0<> ;
: must-find find ; ( overwritten after exceptions )
: ' bl token must-find >body ;
: ['] ' lit, ; immediate
: postpone  bl token must-find
  dup immediate? invert if compile compile then
  >body , ; immediate
                                                             -->
