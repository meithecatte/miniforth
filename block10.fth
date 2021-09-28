( dictionary lookup )
: search-in ( name len first-nt -- nt|0 )
  begin dup while >r
    2dup r@ >name s= r@ visible? and if
      2drop r> exit then
    r> @ repeat >r 2drop r> ;
: find latest @ search-in ;
: >xt ( nt -- xt ) cell+ dup c@ lenmask and + 1+ ;
: immediate? ( nt -- t|f ) cell+ c@ 80 and 0<> ;
: must-find find ; ( overwritten after exceptions )
: ' #bl token must-find >xt ;
: ['] ' lit, ; immediate



                                                             -->
