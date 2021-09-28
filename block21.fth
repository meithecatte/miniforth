( interpret )
: interpreting? ( -- t|f ) compiling? invert ;
: do-nt ( nt -- ? ) dup >xt swap immediate? interpreting? or
  if execute else , then ;
: compile-lit ( d -- ) is-dnum @ if postpone 2literal else
  d>s lit, then ;
: interpret-lit ( d -- ? ) is-dnum @ 0= if d>s then ;
: do-lit  compiling? if compile-lit else interpret-lit then ;
: do-token ( str -- ? ) 2dup find dup if nip nip do-nt else
  drop 2dup word: 2! >number 0= ['] unknown-word and throw
  do-lit then ;
: interpret begin #bl token dup while do-token repeat 2drop ;



                                                             -->
