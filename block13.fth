( >number, continued )
: sc@ ( str len -- str len c|0 ) dup if over c@ else 0 then ;
: ?dup ( x -- x x | 0 ) dup if dup then ;
: >number ( str -- d t | f ) is-dnum off  base @ >r
  sc@ basechar ?dup if  base !  1 /string  then
  sc@ [char] - = dup >r if  1 /string  then
  dup 0= if rdrop 2drop false else
    >digits  r> if dnegate then
    2swap nip 0<> if 2drop false else true then
  then r> base ! ;





                                                             -->
