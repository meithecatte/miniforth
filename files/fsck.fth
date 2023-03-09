( filesystem consistency check )
$6000 constant bitbuf
: >bit'   ( blk -- val addr ) (>bit) bitbuf + ;
: free?   ( blk -- t|f ) >bit' c@ and 0= ;
: (used!) ( blk -- ) >bit' tuck c@ or swap c! ;
: used!   ( blk -- ) dup free? if (used!) else
  red ." multiple references to block " u. cr noclr then ;

: check-blks ( num -- ) 0 ?do i cells blks + @ dup u. used! loop ;
: check-nulls ( num-blks -- ) cells blks + begin dup fsize < while
  dup @ 0<> if
    ." expected 0, got " dup @ u.
  then cell+ repeat drop ;

: check-fid ( fid -- )
  dup used!  open-fid
  ." fid=" dup u.
  fsize 2@ 2dup ud. ." bytes, " #blks dup u. ." blocks: "
  dup check-blks check-nulls cr ;

: check-dir ( fid -- )
  dup check-fid
  0. begin ( fid fpos )
    2>r dup open-fid 2r> fpos 2! fneof?
  while ( fid )
    next-dirent fpos 2@
    ." Checking " dirent-name type space
    dirent-dir? >r
    dirent-blk dup check-fid
    r> if recurse else drop then
  repeat drop ;

: (last-blk) ( -- blk )
  $7FFF begin dup is-free invert while 1- repeat ;

value last-blk

: mismatch ( blk -- )
  dup is-free if
    red ." block " u. ." not marked as used" cr noclr
  else
    dup last-blk <= if
      red ." unused block " u. ." marked as used" cr noclr
    else
      drop
    then
  then ;

: mismatch-byte ( baseblk bits -- )
  8 0 ?do
    dup 1 i lshift and if
      over i + mismatch
    then
  loop 2drop ;

: check-bitbuf ( -- )
  freebits bitbuf begin
    dup bitbuf $1000 + <
  while
    over c@ over c@ <> if
      over c@ over c@ xor >r
      dup bitbuf - 8 u* r> mismatch-byte
    then
    1+ swap 1+ swap
  repeat 2drop ;

: fsck ( -- ) cr
  bitbuf $1000 0 fill
  0 used!
  1 check-dir
  (last-blk) to last-blk
  check-bitbuf ;
