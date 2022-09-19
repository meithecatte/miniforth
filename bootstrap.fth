: >in a02 ;
: run >in ! ;
swap : dp 0 [ dup @ 2 - ! ] ;
: here dp @ ;
: cell+ 2 + ;
: cells dup + ;
: +! dup >r @ + r> ! ;
: allot dp +! ;
: c, here c! 1 allot ;
: , here ! 2 allot ;
: 'lit 0 [ here 4 - @ here 2 - ! ] ;
: lit, 'lit , , ;
: disk# [ lit, ] ;
: base [ lit, ] ;
: st [ lit, ] ;
: latest [ lit, ] ;
: [[ 1 st c! ;
here 2 - @ : 'exit [ lit, ] ;
: create: : [[ ;
: create create: here 3 cells + lit, 'exit , ;
: constant create: lit, 'exit , ;
: variable create 1 cells allot ;
create blk 1 ,
: load' load ;
: load dup blk ! load' ;
: --> blk @ 1 + load ;
: ax 0 ; : cx 1 ; : dx 2 ; : bx 3 ; : sp 4 ; : bp 5 ; : si 6 ; : di 7 ;
: al 0 ; : cl 1 ; : dl 2 ; : bl 3 ; : ah 4 ; : ch 5 ; : dh 6 ; : bh 7 ;
: :code create: 0 3 - allot ;
: stosb, aa c, ; : stosw, ab c, ; : lodsb, ac c, ; : lodsw, ad c, ;
: 2* dup + ;
: 3shl 2* 2* 2* ;
: rm-r, 3shl + c0 + c, ;
: jmp-r, ff c, 4 rm-r, ;
: next, lodsw, ax jmp-r, ;
: movw-rr, 8b c, rm-r, ;
: push, 50 + c, ;
-->
: pop, 58 + c, ;
: movb-ir, b0 + c, c, ;
: int, cd c, c, ;
: movw-ir, b8 + c, , ;
create packet 10 allot
:code int13
si push,
packet si movw-ir,
bx ax movw-rr,
disk# dl movb-ir,
13 int,
ax bx movw-rr,
si pop,
next,
variable pos
: pos, pos @ ! 2 pos +! ;
: make-packet packet pos ! 10 pos, 2 pos, pos, 0 pos, 2* pos, 0 pos, 0 pos, 0 pos, ;
: read-block make-packet 4200 int13 ;
: write-block make-packet 4300 int13 ;
: cr 0D emit 0A emit ;
: incw, 40 + c, ;
: decw, 48 + c, ;
: addw-rr, 03 c, rm-r, ;
: orw-rr, 0b c, rm-r, ;
: andw-rr, 23 c, rm-r, ;
: subw-rr, 2b c, rm-r, ;
: xorw-rr, 33 c, rm-r, ;
: cmpw-rr, 3b c, rm-r, ;
: jb, 72 c, ; : jc, 72 c, ; : jae, 73 c, ; : jnc, 73 c, ;
: jz, 74 c, ; : jnz, 75 c, ; : jbe, 76 c, ; : ja, 77 c, ;
: jl, 7c c, ; : jge, 7d c, ; : jle, 7e c, ; : jg, 7f c, ;
: j> here 0 c, ;
: >j dup >r 1 + here swap - r> c! ;
: j< here ;
: <j here 1 + - c, ;
: p dup c@ u. 1 + ;
: :cmp :code ax ax xorw-rr, ;
: cmp; j> ax decw, >j ax bx movw-rr, next, ;
:cmp 0= bx bx orw-rr, jnz, cmp;
-->
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
: #bl 20 ; : space #bl emit ;
:code 1+ bx incw, next,
: count dup 1+ swap c@ ;
1F constant lenmask
: >name cell+ count lenmask and ;
: visible? cell+ c@ 40 and 0= ;
: words-in begin dup while
dup visible? if dup >name type space then
@ repeat drop ;
: words latest @ words-in ;
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
-->
:code pick
bx bx addw-rr,
sp bx addw-rr,
[bx] bx movw-mr,
next,
: notw-r, F7 c, 2 rm-r, ;
:code invert bx notw-r, next,
: false 0 ; : true ffff ;
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
: move >r over over u< if r> cmove> else r> cmove then ;
40 constant line-length
10 constant #lines
: show-line dup u. dup line-length type cr line-length + ;
: list #lines begin >r show-line r> 1 - dup 0= until drop drop ; 
-->
: skip begin dup >in @ c@ = while 1 >in +! repeat ;
variable sep
: sep? dup 0= swap sep @ = or ;
: +sep dup c@ 0<> if 1+ then ;
: parse sep ! >in @ dup begin
dup c@ sep? invert while 1+ repeat
dup +sep >in ! over - ;
: token skip parse ;
: char #bl token drop c@ ;
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
: blank-rest srcpos @ dup next-line dup srcpos ! #bl fill-range ;
: skip-space 1 >in +! ;
: ln skip-space s+ blank-rest ;
: clear #bl fill ;
-->
( stack manipulation )
: nip ( ab--b) swap drop ;  : tuck ( ab--bab) swap over ;
: rot ( abc--bca) >r swap r> swap ;  : -rot rot rot ;
:code 2swap ( c d a b -- a b c d )
  ax pop, dx pop, cx pop,
  ax push, bx push, cx push, dx bx movw-rr, next,
:code 1- bx decw, next,         : cell- 2 - ;
: literal lit, ; immediate      : negate  0 swap - ;
: within ( n lo hi -- f|t ) over - >r - r> u< ;
: s8? ( n -- f|t ) FF80 80 within ;
: +m-r, ( off m r -- ) 3shl + over s8? if 40 + c, c, else
  80 + c, , then ;      : +r-m, ( off r m -- ) swap +m-r, ;
: movw+mr, 8B c, +m-r, ;        : movw+rm, 89 c, +r-m, ;
: rpick: ( off -- ) 1+ cells negate :code
  bx push, [di] bx movw+mr, next, ;
0 rpick: r@     1 rpick: rover  2 rpick: 2rpick              -->
( double-cell values, stored little endian - ANS be damned )
: s>d dup 0< ;  : d>s drop ;    : d0<> or 0<> ;
: 2@ dup @ swap cell+ @ ;       : 2! swap over cell+ ! ! ;
: 2literal swap lit, lit, ; immediate
: 2variable create 2 cells allot ;
: 2constant : [[ swap lit, lit, 'exit , ;
: 2>r compile swap compile >r compile >r ; immediate
: 2r> compile r> compile r> compile swap ; immediate
: 2r@ compile rover compile r@ ; immediate
: mulw-r,  F7 c, 4 rm-r, ;      : adcw-rr,  13 c, rm-r, ;
:code um* ( u u -- ud ) ax pop, bx mulw-r, ax push,
  dx bx movw-rr, next,          : u*  um* d>s ;
:code d+  ax pop, dx pop, cx pop,
  cx ax addw-rr,  dx bx adcw-rr,  ax push, next,
: ud*u ( ud u -- ud ) tuck u* >r um* r> + ;
: dnegate invert swap invert swap 1 0 d+ ; : d- dnegate d+ ; -->
( strings )
: exit 'exit , ; immediate      : compiling? st c@ 0= ;
: mem= ( a1 a2 len -- t|f ) begin dup while >r
  over c@ over c@ <> if rdrop 2drop false exit then
  1+ swap 1+ swap r> 1- repeat drop 2drop true ;
: s= ( addr len addr len -- t|f )
  2 pick <> if drop 2drop false else swap mem= then ;
: (slit) r> dup cell+ swap @ ( addr len ) 2dup + >r ;
: n, ( addr len -- ) here swap dup allot cmove ;
: slit, ( addr len -- )  compile (slit)  dup ,  n, ;
: s" ( rt: -- addr len )
  skip-space [char] " parse
  compiling? if slit, else
    here swap 2dup >r >r cmove r> r>
  then ; immediate
: /string ( str len n -- str+n len-n ) tuck - >r + r> ;      -->
( dictionary lookup )
: search-in ( name len first-nt -- nt|0 )
  begin dup while >r
    2dup r@ >name s= r@ visible? and if
      2drop r> exit then
    r> @ repeat >r 2drop r> ;
: find latest @ search-in ;
: >xt ( nt -- xt ) cell+ dup c@ lenmask and + 1+ ;
: immediate? ( nt -- t|f ) cell+ c@ 80 and 0<> ;
: must-find find ; ( overwritten after exceptions )
: ' #bl token must-find >xt ;
: ['] ' lit, ; immediate



                                                             -->
( postpone postpone{ )
: (postpone) ( str -- ) must-find dup immediate? invert
  if compile compile then   >xt , ;
: postpone  #bl token (postpone) ; immediate
: postpone{ begin #bl token 2dup s" }" s= invert while
  (postpone) repeat 2drop ; immediate









                                                             -->
( :noname recurse )
: link, ( list -- ) here swap  dup @ ,  ! ;
: header, ( name len -- ) latest link, dup c, n, ;
: rel@ ( a -- v ) dup @ + cell+ ;
: rel! ( v a -- ) dup >r - 1 cells - r> ! ;
: rel, ( v -- ) here rel! 1 cells allot ;
latest @ >xt 1+ rel@ constant 'docol
: call, E8 c, rel, ;
: hide latest @ cell+ dup >r c@ 40 or r> c! ;
: unhide latest @ cell+ dup >r c@ 40 invert and r> c! ;
: :noname ( -- xt ) s" " header, here 'docol call, hide ] ;
: recurse  latest @ >xt , ; immediate                        -->




( exception handling )

:code sp! bx sp movw-rr, bx pop, next,
:code rp@ bx push, di bx movw-rr, next,
:code rp! bx di movw-rr, bx pop, next,
:code execute bx ax movw-rr, bx pop, ax jmp-r,
variable catch-rp
: catch ( i*x xt -- j*x 0 | i*x n )
  sp@ >r  catch-rp @ >r
  rp@ catch-rp !
  execute 0
  r> catch-rp ! rdrop ;
: throw  dup if
  catch-rp @ rp!  r> catch-rp !
  r> swap >r sp!  drop ( the xt slot )  r>
else drop then ;                                             -->
( structured exceptions )
: exception ( -- dict-pos ) latest @ ;
: print-uint @ u. ; : uint ['] print-uint , variable ;
: print-str 2@ type ; : str ['] print-str , 2variable ;
: var #bl token 2dup must-find  dup 1 cells - @ ,
  >r header, 'docol call, r>  >xt , postpone ; ;
: print-name, ( nt -- ) >name postpone{ 2literal type } ;
: print-field, ( nt -- ) dup print-name,  postpone space
  dup >xt ,  1 cells - @ ,  postpone cr ;
: end-exception ( dict-pos -- ) latest @
  :  latest @ print-name,  postpone cr
  begin ( end-pos cur-pos ) 2dup <> while
    dup print-field,  @
  repeat  2drop  postpone ;  ;
                                                             -->

( defer )
exception  str defer-vector:  end-exception unset-defer
: bad-defer ( nt -- ) >name defer-vector: 2!
  ['] unset-defer throw ;
: defer  : latest @ postpone{ literal bad-defer ; } ;
E9 constant jmp16
: defer! ( target-xt defer-xt ) jmp16 over c! 1+ rel! ;
: defer@ ( xt -- xt' ) dup c@ jmp16 = if 1+ rel@ then ;
: is ( xt -- ) compiling? if postpone{ ['] defer! }
  else ' defer! then ; immediate
exception  str word:  end-exception unknown-word
:noname 2dup word: 2! find
  dup 0= ['] unknown-word and throw ; is must-find
:noname #bl token header, 'docol call, ; is create:
:noname create: hide ] ; is :
:noname postpone{ exit [ } unhide ; is ;                     -->
( case )
: case 0 ; immediate
: (of) ( a b -- skip: a | cont: )
  over = if
    drop r> cell+ >r
  else
    r> @ >r
  then ;
: of postpone (of) br> ; immediate
: endof >r postpone (branch) br> r> >br ; immediate
: endcase  postpone drop
  begin dup while >br repeat drop ; immediate



                                                             -->
( key accept )
:code key  bx push, ax ax xorw-rr, 16 int, ax bx movw-rr, next,
8 constant #bs   D constant #cr   A constant #lf
: printable? dup 20 >= swap 7E <= and ;
: append ( str len c -- str len+1 ) >r 2dup + r> swap c! 1+ ;
: unemit  #bs emit  space  #bs emit ;
: accept ( buf max-len -- buf len ; stores max-len on rstack )
  >r 0  begin ( buf cur-len )
    key FF and ( TODO: how to handle extended keys )
    dup printable? if
      over r@ < if  dup emit append  else drop then
    else case
      #cr of  rdrop exit  endof
      #bs of  dup 0<> if  1 -  unemit  then  endof
    endcase then
  again ;                                                    -->
( >number )
: [within] char char 1+ postpone{ 2literal within } ; immediate
: digit ( c -- f | v t ) dup [within] 0 9 if [char] 0 - else
  dup [within] A Z if [char] A - A + else
  dup [within] a z if [char] a - A + else
  drop false exit then then then
  dup base @ < if true else drop false then ;
: basechar ( c -- base | 0 ) case
  [char] # of A endof       [char] $ of 10 endof
  [char] % of 2 endof       dup of 0 endof  endcase ;
: on true swap ! ;  : off false swap ! ;  variable is-dnum
: >digits ( str -- str' ud' ) 0 0 2>r  begin dup while
  over c@  [char] . = if  1 /string  is-dnum on  else
  over c@  digit if s>d 2r> base @ ud*u d+ 2>r  1 /string else
  2r> exit then then repeat 2r> ;
                                                             -->
( >number, continued )
: sc@ ( str len -- str len c|0 ) dup if over c@ else 0 then ;
: ?dup ( x -- x x | 0 ) dup if dup then ;
create all-dnums false ,
: >number ( str -- d t | f ) all-dnums @ is-dnum !  base @ >r
  sc@ basechar ?dup if  base !  1 /string  then
  sc@ [char] - = dup >r if  1 /string  then
  dup 0= if rdrop 2drop false else
    >digits  r> if dnegate then
    2swap nip 0<> if 2drop false else true then
  then r> base ! ;                                           -->





( block utilities )
exception  uint block:  uint error:  end-exception i/o-error
: movb-rr, 8A c, rm-r, ;        : movb-rm, 88 c, r-m, ;
:code hibyte bh bl movb-rr, 0 bh movb-ir, next,
:code lobyte 0 bh movb-ir, next,    : movb-mr, 8A c, m-r, ;
: err? ( u--) hibyte dup error: ! 0<> ['] i/o-error and throw ;
: read-block ( n addr -- ) over block: ! read-block err? ;
: write-block ( n addr -- ) over block: ! write-block err? ;
: blk? ( blk# -- ) cr dup u. 600 read-block 600 40 type ;
: index ( lo hi -- ) swap begin 2dup >= while
  dup blk? 1+ repeat 2drop ;
: copy-block ( from to--) swap 600 read-block 600 write-block ;
: copy-disjoint ( [lo; hi] [to -- )
  begin >r 2dup <= r> swap while
    2 pick over copy-block
  1+ 2>r 1+ 2r> repeat drop 2drop ;                          -->
( interpret )
: interpreting? ( -- t|f ) compiling? invert ;
: do-nt ( nt -- ? ) dup >xt swap immediate? interpreting? or
  if execute else , then ;
: compile-lit ( d -- ) is-dnum @ if postpone 2literal else
  d>s lit, then ;
: interpret-lit ( d -- ? ) is-dnum @ 0= if d>s then ;
: do-lit  compiling? if compile-lit else interpret-lit then ;
: do-token ( str -- ? ) 2dup find dup if nip nip do-nt else
  drop 2dup word: 2! >number 0= ['] unknown-word and throw
  do-lit then ;
: interpret begin #bl token dup while do-token repeat 2drop ;



                                                             -->
( quit )
: ."  postpone s"  compiling? if postpone type else type then
  ; immediate
create no-->  false ,   : --> no--> @ invert if --> then ;
: refill-kbd no--> off 0 500 dup >in ! 100 accept + c!  space ;
: refill ( don't stop processing this block at "quit" below ) ;
: prompt compiling? if ."  compiled" else ."  ok" then cr ;
: repl begin refill interpret prompt again ;
:noname 1 st c! ; is [          :noname 0 st c! ; is ]
rp@ constant r0
: quit begin postpone [  r0 rp!  10 base !
  ['] repl catch  cr execute again ;
:noname ; is skip-space
: list cr list ;
quit            ' refill-kbd is refill                       -->

( division )
: divw-r,  F7 c, 6 rm-r, ;
:code (um/mod) dx pop, ax pop, bx divw-r,
  dx push, ax bx movw-rr, next,
exception end-exception division-by-zero
exception end-exception division-overflow
: um/mod ( ud u -- mod quot )
  dup 0= ['] division-by-zero and throw
  2dup >= ['] division-overflow and throw  (um/mod) ;
: u/mod ( u u -- mod quot ) 0 swap um/mod ;
: ud/mod ( ud u -- mod dquot )
  tuck u/mod >r ( lo div hi R: hi-res )
  swap um/mod r> ;
: u/ ( u u -- quot ) u/mod nip ;
: umod ( u u -- mod ) u/mod drop ;
                                                             -->
( <# #> )
create holdbuf $100 allot  here constant endhold
variable holdptr
: <# ( -- ) endhold holdptr ! ;
: nhold ( -- u ) endhold  holdptr @ - ;
: #> ( xd -- str ) 2drop  holdptr @ nhold ;
exception end-exception hold-area-exhausted
: hold ( c -- ) -1 holdptr +!  holdptr @
  dup holdbuf <  ['] hold-area-exhausted and throw  c! ;
: holds ( str -- ) begin dup while 1-  2dup + c@ hold  repeat ;
: >digit ( u -- c ) dup 9 > if #10 - [char] A + else
  [char] 0 + then ;
: # ( ud -- ud ) base @ ud/mod 2>r >digit hold 2r> ;
: d= ( xd xd -- t|f ) >r swap r> = >r = r> and ;
: #s ( ud -- 0. ) begin # 2dup 0. d= until ;                 -->

( numeric output )
: decimal #10 base ! ;          : hex #16 base ! ;
: ud. ( ud -- ) <# #s #> type space ;
: d. ( d -- ) dup 0< if [char] - emit dnegate then ud. ;
:noname 0 ud. ; is u.           : .  s>d d. ;
: spaces ( u -- ) begin dup while 1- space repeat drop ;
: type.r ( str n -- ) 2dup < if over - spaces else drop then
  type ;
: u.r ( u w -- ) >r 0 <# #s #> r> type.r ;
: .r ( n w -- ) over 0>= if u.r else >r negate
  0 <# #s [char] - hold #> r> type.r then ;
: hex. ( u -- ) ." $" base @ swap hex u. base ! ;
: depth.  ." <" depth 0 u.r ." > " ;
: .s depth. depth begin dup while dup pick . 1- repeat drop ;
: u.s depth. depth begin dup while dup pick u. 1- repeat drop ;
: ?  @ dup . hex. ;                                          -->
( halt during key )
: hlt, F4 c, ;                  :code halt hlt, next,
:code waitkey j< hlt, 1 ah movb-ir, 16 int, jz, <j next,
:code key' bx push, ax ax xorw-rr, 16 int, ax bx movw-rr, next,
:noname  waitkey key' ; is key










                                                             -->
( does> / structures / value )
: >exit ( nt -- @exit ) >xt [ 3 2 cells + ] literal + ;
: >body ( xt -- body ) [ 3 3 cells + ] literal + ;
: does, here 6 + si movw-ir, next, ;
: (does>) r> latest @ >exit ! ;
: does> postpone (does>) does, ; immediate

: +field ( off sz -- off ) create over , + does> @ + ;
: field:  1 cells +field ;      : cfield: 1 +field ;
: 2field: 2 cells +field ;

: value  create 0 , does> @ ;
: to  ' >body  compiling? if postpone{ literal ! }
  else ! then ; immediate

                                                             -->
( counted loops )
variable leaves                 0 rpick: i   2 rpick: j
: subw-sr, 83 c, 5 rm-r, c, ;   : unloop, 2 cells di subw-sr, ;
:code unloop unloop, next,      :code 2rdrop unloop, next,
: leave postpone (branch) leaves link, ; immediate
: >leave leaves @ begin dup while dup @ swap >br repeat drop ;
: begin-loop leaves @ 0 leaves ! ;
: end-loop <br >leave   leaves !  postpone unloop ;
: do begin-loop postpone 2>r br< ; immediate
: ?do begin-loop postpone{ 2dup 2>r <> (0branch) } leaves link,
  br< ; immediate




                                                             -->
( counted loops cont. )
: jo, 70 c, ;   : jno, 71 c, ;  : subw-ir, 81 c, 5 rm-r, , ;
:code (+loop)   ( shift everything st upper-limit = $8000 )
  -2 cells [di] dx movw+mr,  $8000 dx subw-ir,
  -1 cells [di] cx movw+mr,  dx cx subw-rr,
  bx cx addw-rr, bx pop,
  lodsw, jo, j>
    ax si movw-rr,
    dx cx addw-rr,  -1 cells cx [di] movw+rm,
  >j next,
: +loop postpone (+loop) end-loop ; immediate
: loop 1 lit, postpone +loop ; immediate



                                                             -->
( stack variables )
0 field: stk.bot
  field: stk.pos
  field: stk.top
 2field: stk.name
constant stk-header
exception str stack: end-exception stack-overflow
: overflow? ( pos stk -- pos ) 2dup stk.top @ <= if drop else
  stk.name 2@ stack: 2! ['] stack-overflow throw then ;
: push ( val stk -- ) dup stk.pos @ dup >r cell+ over overflow?
  swap stk.pos ! r> ! ;
exception str stack: end-exception stack-underflow
: underflow? ( pos stk -- pos ) 2dup stk.bot @ >= if drop else
  stk.name 2@ stack: 2! ['] stack-underflow throw then ;
: pop ( stk -- val ) dup stk.pos @ cell- over underflow?
  ( stk pos ) tuck swap stk.pos ! @ ;                        -->
( stack variables cont. )
: 2,  swap , , ;
: stack ( max-depth ) cells create  here stk-header +
  ( sz buf ) dup , dup , over + ,  latest @ >name 2,  allot ;
: stk.iter> ( stk -- top bot ) dup stk.pos @ swap stk.bot @ ;
: >next 1 cells lit, postpone +loop ; immediate
: stk.iter< ( stk -- bot top ) stk.iter> swap cell- ;
: <next 1 cells negate lit, postpone +loop ; immediate
: peek ( stk -- val ) dup stk.pos @ cell- swap underflow? @ ;
: stk.depth ( stk -- u ) dup stk.pos @ swap stk.bot @ - 2/ ;





                                                             -->
( colored output )
:code emit-tty bx ax movw-rr, 0E ah movb-ir, bx bx xorw-rr,
  10 int, bx pop, next,
:code curpos@ bx push, bx bx xorw-rr, 3 ah movb-ir, 10 int,
  dx bx movw-rr, next,
:code curpos! bx dx movw-rr, 2 ah movb-ir, bx bx xorw-rr,
  10 int, bx pop, next,

create color 7 ,
: fs> 64 c, ; :code fs! 8E c, bx 4 rm-r, bx pop, next,
:code farc! ax pop, fs> al [bx] movb-rm, bx pop, next,
:code farc@ fs> [bx] bl movb-mr, 0 bh movb-ir, next,
: cur>scr dup hibyte #80 u* swap lobyte + 2* ;
: vga! B800 fs! farc! ;         : attr! cur>scr 1+ vga! ;
:noname ( c -- ) dup printable? if color @ curpos@ attr! then
  emit-tty ; is emit                                         -->
( coloring helpers )
: color: ( n -- ) create , does> @ color ! ;
: colors:  0 begin dup $10 < while dup color: 1+ repeat drop ;
colors: black blue green cyan red purple brown noclr
        gray lblue lgreen lcyan lred lpurple yellow white
: refill-kbd white refill-kbd noclr ;   ' refill-kbd is refill









                                                             -->
( naive text searching )
: sfind ( haystack needle -- ptr|0 ) 2>r
  begin dup r@ >= while  over 2r@ tuck s= if 2rdrop exit then
    1 /string repeat  2rdrop 2drop 0 ;
: show-pos ( addr -- ) blk @ 2 u.r ." +" 600 - 3 u.r space ;
: <line 3f invert and ;
: show-line ( addr hl-len -- ) over show-pos
  over dup <line tuck - type  red 2dup type noclr
  + dup 1- next-line over - type  cr ;
: occurs ( haystack needle -- ) 2>r begin 2r@ sfind dup while
  over r@ show-line 1 /string repeat 2rdrop drop ;
: (grep) ( blk-range needle -- ) cr 2>r swap begin 2dup >= while
  dup 600 read-block  dup blk !  600 400 2r@ occurs
  1+ repeat 2drop 2rdrop ;
: grep  #bl token (grep) ;
: grep" postpone s" (grep) ;                                 -->
( vocabularies )
10 stack search-order
create current latest ,         :noname current @ ; is latest
: (vocabulary) create 0 , latest @ , does> search-order push ;
: unlink ( wid -- nt ) dup @ tuck @ swap ! ;
: relink ( nt wid -- ) 2dup @ swap ! ! ;
: move-to ( wid -- ) latest unlink swap relink ;
: definitions ( -- ) search-order peek current ! ;
(vocabulary) Root  (vocabulary) Forth  Root Forth
latest @ ' Forth >body !  definitions
' Root >body  dup dup move-to move-to move-to




                                                             -->
( search-order support for find )
:noname ( name len -- nt|0 ) search-order stk.iter< do
  2dup i @ @ search-in  dup if >r 2drop r> unloop exit then
  drop <next 2drop 0 ; is find
: vocabulary (vocabulary) [ ' Root >body ] literal move-to ;
: vocab. cell+ @ >name type ;
Root definitions
: previous search-order pop drop  search-order stk.depth 0= if
  Root then ;
: order search-order stk.iter> ?do i @ vocab. space >next
  space current @ vocab. ;
: only begin search-order stk.depth 1 > while previous repeat ;
: words  search-order peek @ words-in ;

previous definitions                                         -->

( random words not defined earlier )
: callot ( u -- ) here over allot swap 0 fill ;
: max ( a b -- m ) 2dup < if nip else drop then ;
: min ( a b -- m ) 2dup > if nip else drop then ;
: umax ( a b -- m ) 2dup u< if nip else drop then ;
: umin ( a b -- m ) 2dup u> if nip else drop then ;
: shlw-cl,  D3 c, 4 rm-r, ;
:code lshift  bx cx movw-rr, bx pop, bx shlw-cl, next,
: ud> ( da db -- da>db ) >r swap r> 2dup <> if 2swap then 2drop
  u> ;
: ud<   2swap ud> ;
: ud>=  ud< invert ;
#25 #80 u* 2* constant #vga
: clrscr #vga 0 ?do #bl i vga! 7 i 1+ vga! 2 +loop 0 curpos! ;
$1B constant #esc
: 2over ( a. b. -- a. b. a. ) 2>r 2dup 2r> 2swap ;           -->
( far cmove )
: push-es, 06 c, ;              : pop-es, 07 c, ;
: push-fs, 0F c, A0 c, ;        : pop-fs, 0F c, A1 c, ;
:code fs-cmove bx cx movw-rr,   si ax movw-rr, di dx movw-rr,
  di pop, si pop,    push-es,  push-fs, pop-es,
  fs> rep, movsb,    pop-es, ax si movw-rr, dx di movw-rr,
  bx pop,  next,









