( stack variables )
0 field: stk.bot
  field: stk.pos
  field: stk.top
 2field: stk.name
constant stk-header
exception str stack: end-exception stack-overflow
: overflow? ( pos stk -- pos ) 2dup stk.top @ <= if drop else
  stk.name 2@ stack: 2! ['] stack-overflow throw then ;
: push ( val stk -- ) dup stk.pos @ dup >r cell+ over overflow?
  swap stk.pos ! r> ! ;
exception str stack: end-exception stack-underflow
: underflow? ( pos stk -- pos ) 2dup stk.bot @ >= if drop else
  stk.name 2@ stack: 2! ['] stack-underflow throw then ;
: pop ( stk -- val ) dup stk.pos @ cell- over underflow?
  ( stk pos ) tuck swap stk.pos ! @ ;                        -->
