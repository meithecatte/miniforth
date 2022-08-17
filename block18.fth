( <# #> )
create holdbuf $100 allot  here constant endhold
variable holdptr
: <# ( -- ) endhold holdptr ! ;
: #> ( xd -- str ) 2drop  holdptr @ endhold over - ;
exception end-exception hold-area-exhausted
: hold ( c -- ) -1 holdptr +!  holdptr @
  dup holdbuf <  ['] hold-area-exhausted and throw  c! ;
: holds ( str -- ) begin dup while 1-  2dup + c@ hold  repeat ;
: >digit ( u -- c ) dup 9 > if #10 - [char] A + else
  [char] 0 + then ;
: # ( ud -- ud ) base @ ud/mod 2>r >digit hold 2r> ;
: d= ( xd xd -- t|f ) >r swap r> = >r = r> and ;
: #s ( ud -- 0. ) begin # 2dup 0. d= until ;

                                                             -->
