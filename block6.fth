: skip begin dup >in @ c@ = while 1 >in +! repeat ;
: parse >r >in @ dup begin
dup c@ dup r@ = swap 0= or invert while
1+ repeat rdrop dup
dup c@ 0<> if 1+ then
>in ! over - ;
: token skip parse ;
: char bl token drop c@ ;
: [char] char lit, ; immediate
: 2drop drop drop ;
: ( [char] ) parse 2drop ; immediate
