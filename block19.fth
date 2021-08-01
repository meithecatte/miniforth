( block utilities )
: blk? ( blk# -- ) 600 read-block drop 600 40 type cr ;
: index ( lo hi -- ) swap begin 2dup >= while
  dup u. dup blk? 1+ repeat 2drop ;
: copy-block ( from to -- )
  swap 600 read-block drop  600 write-block drop ;
: copy-disjoint ( lo hi to -- )
  begin >r 2dup <= r> swap while
    2 pick over copy-block
  1+ 2>r 1+ 2r> repeat drop 2drop ;





                                                             -->
