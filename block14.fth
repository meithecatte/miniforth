( block utilities )
exception  uint block:  uint error:  end-exception i/o-error
: movb-rr, 8A c, rm-r, ;        : movb-rm, 88 c, r-m, ;
:code hibyte bh bl movb-rr, 0 bh movb-ir, next,
:code lobyte 0 bh movb-ir, next,    : movb-mr, 8A c, m-r, ;
: err? ( u--) hibyte dup error: ! 0<> ['] i/o-error and throw ;
: read-block ( n addr -- ) over block: ! read-block err? ;
: write-block ( n addr -- ) over block: ! write-block err? ;
: blk? ( blk# -- ) cr dup u. 600 read-block 600 40 type ;
: index ( lo hi -- ) swap begin 2dup >= while
  dup blk? 1+ repeat 2drop ;
: copy-block ( from to--) swap 600 read-block 600 write-block ;
: copy-disjoint ( [lo; hi] [to -- )
  begin >r 2dup <= r> swap while
    2 pick over copy-block
  1+ 2>r 1+ 2r> repeat drop 2drop ;                          -->
