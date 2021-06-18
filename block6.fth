: skip begin dup >in @ c@ = while 1 >in +! repeat ;
variable sep
: sep? dup 0= swap sep @ = or ;
: +sep dup c@ 0<> if 1+ then ;
: parse sep ! >in @ dup begin
dup c@ sep? invert while 1+ repeat
dup +sep >in ! over - ;
: token skip parse ;
: char bl token drop c@ ;
: [char] char lit, ; immediate
: 2drop drop drop ;
: ( [char] ) parse 2drop ; immediate
:code fill
bx ax movw-rr,
cx pop,
di dx movw-rr, di pop,
rep, stosb,
dx di movw-rr,
bx pop,
next,
