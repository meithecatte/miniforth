( editor: buffer mgmt )
vocabulary Editor    Editor definitions
$C00 constant buf               buf $400 + constant buf-end
variable row    variable col
: >buf ( r c -- addr ) buf + swap blk-width u* + ;
: cur>buf ( -- addr ) row @ col @ >buf ;
: >row ( addr -- u ) blk-width u/ $f and ;
: >col ( addr -- u ) $3f and ;
: buf>cur ( addr -- ) dup >row row !  >col col ! ;

variable dirty  dirty off       value curblk
: (save) curblk buf write-block  dirty off ;
: save ( -- ) dirty @ if (save) then ;
: blk! ( blk -- ) save  to curblk ;
: read ( blk -- ) dup blk!  buf read-block ;
: mark ( -- ) dirty on ;                                     -->
( editor: rendering )
: mojibake 4 curpos@ attr!  $A8 emit ; ( $A8 printable? -> 0 )
create column-colors  blk-width allot
column-colors blk-width 7 fill
: colclr! ( clr col -- ) column-colors + c! ;
f 0 colclr!  f $10 colclr!  f $20 colclr!  f $30 colclr!
$47 $3f colclr!
: (color) ( addr -- ) >col column-colors + c@ color c! ;
: (show) dup printable? if emit else drop mojibake then ;
: show-char ( addr -- ) dup (color) c@ (show) ;
: .lineno ( addr -- ) >row gray decimal 2 u.r space hex ;
: (show-line) blk-width 0 ?do dup show-char 1+ loop ;
: show-line ( addr -- addr ) dup .lineno (show-line) cr ;
                                                             -->


( editor: rendering - cont. )
defer modeline
: modeline-normal ." Editing block $" curblk .
  dirty @ if ."  (dirty)" then ;
' modeline-normal is modeline
: (curpos)  row @ $100 u* col @ 3 + + curpos! ;
: (render) buf  blk-height 0 ?do show-line loop  drop ;
variable need-redraw
( split rendering into the part before and after the modeline
  -- allows displaying a message by: status ." ..." )
: status ( -- ) clrscr (render) white  need-redraw off ;
: ,s ( -- ) status .s ;
: render ( --) need-redraw @ if status modeline then (curpos) ;
                                                             -->


( editor: keymaps )
value keypress
: unbound status ." Unbound key " keypress dup u. emit ;
: keymap create ['] unbound , $100 cells callot does>
  keypress lobyte 1+ cells over + @ ( map handler )
  dup if nip else drop @ then execute ;
: >> latest @ >xt ;
: bind ( xt c -- ) 1+ cells ' >body + ! ;
defer current-keymap            keymap normal
: normal-mode  ['] modeline-normal is modeline
  ['] normal is current-keymap ;
: handle-key  key to keypress  ['] current-keymap catch
  dup if status red execute else drop then ;
: edit-loop normal-mode need-redraw on  begin render
  need-redraw on  handle-key  again ;                        -->

( editor: basic movement )
: quit-editor status quit ; >> char Q bind normal
: move-left  col @ 1- 0   max col ! ; >> char h bind normal
: move-right col @ 1+ $3f min col ! ; >> char l bind normal
: move-up    row @ 1- 0   max row ! ; >> char k bind normal
: move-down  row @ 1+ $f  min row ! ; >> char j bind normal
: move-begin 0 col ! ;                >> char 0 bind normal
: move-top   0 row ! move-begin ;     >> char H bind normal
: move-bot   $f row ! move-begin ;    >> char L bind normal
: move-prev  curblk 1- read ;         >> char [ bind normal
: move-next  curblk 1+ read ;         >> char ] bind normal




                                                             -->
( editor: insert mode )
: line-begin ( u -- u ) $3f invert and ;
: line-end ( u -- u ) $3f or ;
exception end-exception won't-fit-in-buffer
: is#bl ( c -- ) #bl <> ['] won't-fit-in-buffer and throw ;
: has-space ( addr -- addr ) dup line-end c@ is#bl ;
: how-much ( addr -- u ) dup line-end swap - ;
: make-space ( addr -- ) has-space dup 1+ over how-much move ;
: insert-at ( c addr -- ) dup make-space c!  mark ;
: insert-char  cur>buf insert-at  move-right ;
keymap insert  :noname  keypress lobyte printable? if
  keypress insert-char else unbound then ; to insert
' normal-mode #esc bind insert
:noname ." -- INSERT --" ; : insert-mode literal is modeline
  ['] insert is current-keymap ;
' insert-mode  char i bind normal                            -->
( editor: remove character )
: shift-back dup 1+ swap dup how-much move ;
: remove-at ( a -- ) dup shift-back line-end #bl swap c! mark ;
: remove-right cur>buf remove-at ; >> char x bind normal
: remove-left move-left remove-right ; >> char X bind normal
                                       >> #bs bind insert









                                                             -->
( editor: user-facing commands )
Forth definitions
: ed edit-loop ;
: edit read ed ;
: save save ;
: run  save  no--> on  curblk load ;
: bnew status ." Erase this block? (y/n)" key lobyte
  [char] y = if buf 400 clear mark move-top then ed ;
previous definitions
                                                             -->






( editor: line insert )
buf blk-height 1- blk-width u* +  constant last-line
: not-bottom ( -- ) row @ blk-height 1- >=
  ['] won't-fit-in-buffer and throw ;
: has-empty ( -- )
  last-line blk-width 0 do dup c@ is#bl 1+ loop  drop ;
: how-much ( addr -- count ) last-line swap - ;
: insert-line ( addr -- ) has-empty dup dup blk-width +
  over how-much move  blk-width clear  mark ;
: line-above  move-begin cur>buf insert-line ;
: line-below  not-bottom move-down line-above ;
: insert-above line-above insert-mode ; >> char O bind normal
: insert-below line-below insert-mode ; >> char o bind normal
: split-line cur>buf line-below cur>buf 2dup 2dup swap - move
  over - clear ;  >> #cr bind insert
                                                             -->
( editor: scanning )
: wchar?    ( c -- t|f ) $21 $7f within ;
: at-wchar? ( u -- t|f ) c@ wchar? ;
defer scan?
: (scan-fwd) ( [lo; hi[ pred -- u|0 ) is scan?  swap ?do
  i scan? if i unloop exit then   loop 0 ;
: (scan-bck) ( ]lo; hi] pred -- u|0 ) is scan?  ?do
  i scan? if i unloop exit then   -1 +loop 0 ;
: scan-fwd ( <pred> [lo; hi[ -- u|0 )
  postpone{ ['] (scan-fwd) } ; immediate
: scan-bck ( <pred> ]lo; hi] -- u|0 )
  postpone{ ['] (scan-bck) } ; immediate
: line-text-end ( addr -- addr ) dup >r line-begin r> line-end
  over >r scan-bck at-wchar? ?dup if rdrop else r> then ;
: move-end cur>buf line-text-end buf>cur ;
  >> char $ bind normal                                      -->
( editor: fancy ways to enter insert mode )
: append  move-right insert-mode ;      >> char a bind normal
: insert-beg  move-begin insert-mode ;  >> char I bind normal
: append-end  move-end   append ;       >> char A bind normal
                                                             -->











( editor: word-wise movements )
: line-begin? ( u -- t|f ) $3f and 0= ;
: line-end?   ( u -- t|f ) $3f and $3f = ;
: word-begin? ( u -- t|f ) dup >r dup >r
  c@ wchar?  r> 1- c@ wchar? invert  r> line-begin? or and ;
: word-end?   ( u -- t|f ) dup >r dup >r
  c@ wchar?  r> 1+ c@ wchar? invert  r> line-end? or and ;
: ?buf>cur ( u -- ) ?dup if buf>cur then ;
: next-word cur>buf 1+ buf-end scan-fwd word-begin? ?buf>cur ;
  >> char w bind normal  >> char W bind normal
: prev-word cur>buf buf <> if  buf cur>buf 1-
  scan-bck word-begin? ?buf>cur then ;
  >> char b bind normal  >> char B bind normal
: word-end  cur>buf 1+ buf-end scan-fwd word-end? ?buf>cur ;
  >> char e bind normal  >> char E bind normal
previous definitions
