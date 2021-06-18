:code pick
bx bx addw-rr,
sp bx addw-rr,
[bx] bx movw-mr,
next,
: notw-r, F7 c, 2 rm-r, ;
:code invert bx notw-r, next,
