:code pick
bx bx addw-rr,
sp bx addw-rr,
[bx] bx movw-mr,
next,
: notw-r, F7 c, 2 rm-r, ;
:code invert bx notw-r, next,
: true 0 ; : false ffff ;
:cmp u< cx pop, bx cx cmpw-rr, jae, cmp;
:cmp u<= cx pop, bx cx cmpw-rr, ja, cmp;
:cmp u> cx pop, bx cx cmpw-rr, jbe, cmp;
:cmp u>= cx pop, bx cx cmpw-rr, jb, cmp;
:cmp < cx pop, bx cx cmpw-rr, jge, cmp;
:cmp <= cx pop, bx cx cmpw-rr, jg, cmp;
:cmp > cx pop, bx cx cmpw-rr, jle, cmp;
:cmp >= cx pop, bx cx cmpw-rr, jl, cmp;
:cmp 0< bx bx orw-rr, jge, cmp;
:cmp 0<= bx bx orw-rr, jg, cmp;
:cmp 0> bx bx orw-rr, jle, cmp;
:cmp 0>= bx bx orw-rr, jl, cmp;
: appending seek dup u. srcpos ! move-checkpoint ;
: move >r over over u< if r> cmove> else r> cmove then ;
40 constant line-length
10 constant #lines
: show-line dup u. dup line-length type cr line-length + ;
: list #lines begin >r show-line r> 1 - dup 0= until drop drop ; 
: r@ r> r> dup >r swap >r ;
