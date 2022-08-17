( editor: buffer mgmt )
vocabulary Editor    Editor definitions
$C00 constant buf               buf $400 + constant buf-end
variable row    variable col
: >buf ( r c -- addr ) buf + swap line-length u* + ;
: cur>buf ( -- addr ) row @ col @ >buf ;
: >row ( addr -- u ) line-length u/ $f and ;
: >col ( addr -- u ) $3f and ;
: buf>cur ( addr -- ) dup >row row !  >col col ! ;

variable dirty  dirty off       value curblk
: (save) curblk buf write-block  dirty off ;
: save ( -- ) dirty @ if (save) then ;
: blk! ( blk -- ) save  to curblk ;
: read ( blk -- ) dup blk!  buf read-block ;
: mark ( -- ) dirty on ;                                     -->
