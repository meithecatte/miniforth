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
variable checkpoint
variable srcpos
: s+ srcpos @ s: dup u. srcpos ! ;
: move-checkpoint srcpos @ checkpoint ! ;
: doit checkpoint @ run move-checkpoint ;
: appending seek dup u. srcpos ! move-checkpoint ;
: next-line 3f or 1+ ;
: 2dup over over ;
: fill-range >r over - r> fill ;
: terminate 0 srcpos @ c! ;
: blank-rest srcpos @ dup next-line dup srcpos ! bl fill-range ;
: skip-space 1 >in +! ;
: ln skip-space s+ blank-rest ;
-->
