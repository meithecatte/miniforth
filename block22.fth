( naive text searching )
: sfind ( haystack needle -- ptr|0 ) 2>r
  begin dup r@ >= while  over 2r@ tuck s= if 2rdrop exit then
    1 /string repeat  2rdrop 2drop 0 ;
: show-pos ( addr -- ) blk @ 2 u.r ." +" 600 - 3 u.r space ;
: <line 3f invert and ;
: show-line ( addr hl-len -- ) over show-pos
  over dup <line tuck - type  red 2dup type noclr
  + dup 1- next-line over - type  cr ;
: occurs ( haystack needle -- ) 2>r begin 2r@ sfind dup while
  over r@ show-line 1 /string repeat 2rdrop drop ;
: (grep) ( blk-range needle -- ) cr 2>r swap begin 2dup >= while
  dup 600 read-block  dup blk !  600 400 2r@ occurs
  1+ repeat 2drop 2rdrop ;
: grep  #bl token (grep) ;
: grep" postpone s" (grep) ;                                 -->
