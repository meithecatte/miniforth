Files definitions

( copy files )
: copy-fid ( from-fid to-fid )
  over ( from ) open-fid
  fsize 2@ 2>r
  dup ( to ) open-fid
  2r> 2dup fsize!
  #blks 0 ?do
    over ( from ) open-fid i fb!
    dup ( to ) open-fid i fb ! fblk-dirty on undirty
  loop
  2drop ;

: cp ( from-fname to-fname )
  2>r fopen cur-fid @ 2r>
  fcreate cur-fid @
  copy-fid ;

previous definitions
