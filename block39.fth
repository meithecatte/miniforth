( editor: rendering )
#25 #80 u* 2* constant #vga
: clrscr #vga 0 ?do #bl i vga! 7 i 1+ vga! 2 +loop 0 curpos! ;
: mojibake 4 curpos@ attr!  $A8 emit ; ( $A8 printable? -> 0 )
create column-colors  line-length allot
column-colors line-length 7 fill
: colclr! ( clr col -- ) column-colors + c! ;
f 0 colclr!  f $10 colclr!  f $20 colclr!  f $30 colclr!
$47 $3f colclr!
: (color) ( addr -- ) >col column-colors + c@ color c! ;
: (show) dup printable? if emit else drop mojibake then ;
: show-char ( addr -- ) dup (color) c@ (show) ;
: .lineno ( addr -- ) >row gray decimal 2 u.r space hex ;
: (show-line) line-length 0 ?do dup show-char 1+ loop ;
: show-line ( addr -- addr ) dup .lineno (show-line) cr ;
                                                             -->
