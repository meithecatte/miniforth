( 64K should be enough for everybody, right? )
( at least to get to protected mode? )
( well, apparently I was too wasteful. )
( and reengineering everything is not my idea of a good time. )

: retf, $CB c, ;

:code ds>fs-cmove ( src dst count -- )
  bx cx movw-rr,
  si ax movw-rr,  di dx movw-rr,
  di pop, si pop,
  push-es, push-fs, pop-es,
  rep, movsb,
  pop-es,
  ax si movw-rr,  dx di movw-rr,
  bx pop,
  next,

variable saved-sp
variable saved-rp

: >alter ( n -- seg ) #12 lshift ;
: mk-alter ( n -- ) undirty >alter fs!
  sp@ saved-sp !
  rp@ saved-rp !
  0 0 FFFF ds>fs-cmove ;  ( the last byte doesn't matter anyway )

:code (switched)
  cs ax movw-sr,
  ax ds movw-rs,
  ax es movw-rs,
  ax ss movw-rs,
  [#] sp movw-mr, saved-sp ,
  [#] di movw-mr, saved-rp ,
  bx pop,
  ' mount ax movw-ir,
  ax jmp-r,

:code (switch) ( target-seg -- )
  bx push,
  ' (switched) ax movw-ir,  ax push,
  retf,

: switch ( target-alter -- )
  sp@ cell+ saved-sp !
  rp@ saved-rp !
  undirty >alter (switch) ;
: sw  switch ;

( to make load work outside of alter 0 )
:noname  dup blk !  600 read-block  0 a00 c!  600 >in ! ; is load

: mk-alters ( -- )
  ( mk-alter behaves kinda like UNIX fork, so... )
  2 begin dup 7 <= ds@ 0= and while dup mk-alter 1+ repeat drop
  ds@ 2000 = if s" fed.fth" exec then ;

mk-alters
