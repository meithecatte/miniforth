( stack variables cont. )
: 2,  swap , , ;
: stack ( max-depth ) cells create  here stk-header +
  ( sz buf ) dup , dup , over + ,  latest @ >name 2,  allot ;
: stk.iter> ( stk -- top bot ) dup stk.pos @ swap stk.bot @ ;
: >next 1 cells lit, postpone +loop ; immediate
: stk.iter< ( stk -- bot top ) stk.iter> swap cell- ;
: <next 1 cells negate lit, postpone +loop ; immediate
: peek ( stk -- val ) dup stk.pos @ cell- swap underflow? @ ;
: stk.depth ( stk -- u ) dup stk.pos @ swap stk.bot @ - 2/ ;





                                                             -->
