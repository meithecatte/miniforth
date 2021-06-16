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
: constant : [[ lit, 'exit , ;
: create : [[ here 3 cells + lit, 'exit , ;
: variable create 1 cells allot ;
variable checkpoint
variable srcpos
: s+ srcpos @ s: dup u. srcpos ! ;
: move-checkpoint srcpos @ checkpoint ! ;
: doit checkpoint @ run move-checkpoint ;
variable x
: lobyte x ! x c@ ;
: hibyte x ! x 1 + c@ ;
: 2* dup + ;
: s 2* dup >r hibyte + r> lobyte ;
: nb 0 swap s s s s s s s s drop ;
: nbw dup hibyte nb swap lobyte nb + ;
: 1bit nbw nb nb nb ;
: (branch) r> @ >r ;
create bb 2 cells allot
: (0branch) r> dup @ bb ! cell+ bb cell+ !
1bit cells bb + @ >r ;
2 load
