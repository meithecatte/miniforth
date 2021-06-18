: rep, F2 c, ;
: movsb, A4 c, ; : movsw, A5 c, ; : cmpsb, A6 c, ; : cmpsw, A7 c, ;
:code cmove
bx cx movw-rr,
si ax movw-rr, di dx movw-rr,
di pop, si pop,
rep, movsb,
ax si movw-rr, dx di movw-rr,
bx pop, next,
: cld, FC c, ; : std, FD c, ;
:code (cmove>)
bx cx movw-rr,
si ax movw-rr, di dx movw-rr,
di pop, si pop,
std, rep, movsb, cld,
ax si movw-rr, dx di movw-rr,
bx pop, next,
: cmove> dup >r 1 - dup >r + swap r> + swap r> (cmove>) ;
: bl 20 ; : space bl emit ;
:code 1+ bx incw, next,
: count dup 1+ swap c@ ;
1F constant lenmask
: header-name cell+ count lenmask and ;
: visible? cell+ c@ 40 and 0= ;
: words-at begin dup while
dup visible? if dup header-name type space then
@ repeat drop ;
: words latest @ words-at ;
sp@ constant s0
: sarw1, D1 c, 7 rm-r, ;
:code 2/ bx sarw1, next,
: depth sp@ s0 swap - 2/ ;
: [bx+si] 0 ; : [bx+di] 1 ; : [bp+si] 2 ; : [bp+di] 3 ;
: [si] 4 ; : [di] 5 ; : [#] 6 ; : [bp] 6 ; : [bx] 7 ;
: m-r, 3shl + c, ;
: r-m, swap m-r, ;
: movw-mr, 8B c, m-r, ;
: movw-rm, 89 c, r-m, ;
