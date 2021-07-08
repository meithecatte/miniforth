( strings )
: exit 'exit , ; immediate      : compiling? st c@ 0= ;
: s= ( addr len addr len -- t|f )
  2 pick <> if drop drop drop false exit then
  swap begin ( a1 a2 len ) dup while >r
  over c@ over c@ <> if rdrop 2drop false exit then
  1+ swap 1+ swap r> 1 - repeat drop 2drop true ;
: (slit) r> dup cell+ swap @ ( addr len ) 2dup + >r ;
: n, ( addr len -- ) here swap dup allot cmove ;
: slit, ( addr len -- )  compile (slit)  dup ,  n, ;
: s" ( rt: -- addr len )
  skip-space [char] " parse
  compiling? if slit, else
    here swap 2dup >r >r cmove r> r>
  then ; immediate
: /string ( str len n -- str+n len-n ) tuck - >r + r> ;      -->
