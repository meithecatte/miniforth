:cmp 0<> bx bx orw-rr, jz, cmp;
:cmp = cx pop, bx cx cmpw-rr, jnz, cmp;
:cmp <> cx pop, bx cx cmpw-rr, jz, cmp;
: compile r> dup cell+ >r @ , ;
: immediate latest @ cell+ dup >r c@ 80 + r> c! ;
:code (branch)
lodsw,
ax si movw-rr,
next,
:code (0branch)
lodsw,
bx bx orw-rr,
jnz, j>
ax si movw-rr,
>j
bx pop,
next,
: br> here 0 , ;
: >br here swap ! ;
: br< here ;
: <br , ;
: if compile (0branch) br> ; immediate
: then >br ; immediate
: else >r compile (branch) br> r> >br ; immediate
: begin br< ; immediate
: again compile (branch) <br ; immediate
: until compile (0branch) <br ; immediate
: while compile (0branch) br> swap ; immediate
: repeat compile (branch) <br >br ; immediate
: seek begin dup c@ 0<> while 1 + repeat ;
: type begin dup while 1 - >r dup c@ emit 1 + r> repeat drop drop ;
: over >r dup r> swap ;
: rdrop r> r> drop >r ;
:code or ax pop, ax bx orw-rr, next,
:code and ax pop, ax bx andw-rr, next,
:code xor ax pop, ax bx xorw-rr, next,
:code sp@ bx push, sp bx movw-rr, next,
-->
