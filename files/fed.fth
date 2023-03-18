( the file editor )
vocabulary Fed
Fed definitions

( buffer management )
: (buf) $1000 fs! ;
: b@ (buf) farc@ ;
: b! (buf) farc! ;

variable #buf  0 #buf !
variable dirty
: mark  dirty on ;

variable buf-cwd
create buf-filename $80 allot
: filename! ( name len -- ) dup buf-filename c!
  >r buf-filename 1+ r> cmove ;
: filename@ ( -- name len ) buf-filename count ;
: cappend ( c -- ) #buf @ b! 1 #buf +! ;
: sappend ( s u -- ) over + swap ?do i c@ cappend loop ;

( file reading )
$1000 constant iobuf
$1000 constant iobuf-size

( error out if the file is larger than 64K )
exception var filename: end-exception file-too-large
: check-fsize ( -- ) fsize 2@ 0<> ['] file-too-large and throw drop ;

: #read ( -- u ) bytes-left d>s iobuf-size umin ;
: (read) ( -- ) check-fsize
  begin fneof? while iobuf #read dup >r fread
  iobuf r> sappend repeat ;
: eol? ( -- ? ) #buf @ if #buf @ 1- b@ #lf = else false then ;
: ensure-eol ( -- ) eol? invert if #lf cappend mark then ;
: read-file ( name len -- ) cwd buf-cwd !  2dup filename!
  0 #buf !  fopen? if (read) dirty off then ensure-eol ;

ensure-eol

( file saving )
: prepare-buf ( b len -- ) iobuf swap 0 ?do over b@ over c!
  1+ swap 1+ swap loop 2drop ;
: #write ( b -- b u ) #buf @ over - iobuf-size umin ;
: (save) ( -- ) buf-cwd @ cwds push
  buf-filename count fcreate
  0 begin
    dup #buf @ <
  while
    dup #write dup >r prepare-buf
    $1000 r@ fwrite r> +
  repeat drop
  undirty 
  cwds pop drop ;
: save ( -- ) dirty @ if (save) dirty off then ;

( writing to VGA canvas without going through the BIOS )
variable cx     variable cy
: line-space?    cx @ #80 < ;
: screen-space?  cy @ #25 < ;
: editor-space?  cy @ #24 < ;
: >vga ( -- addr ) cy @ #80 u*  cx @ + 2* ;
: putc ( c -- ) >vga dup >r vga!  color @ r> 1+ vga!  1 cx +! ;
: puts ( s u -- ) 0 ?do dup c@ putc 1+ loop drop ;
: newline ( -- ) 0 cx !  1 cy +! ;
: fill-line ( -- ) begin line-space? while #bl putc repeat ;
: fill-rest ( -- ) begin editor-space? while fill-line newline repeat ;

variable old-emit
: begin-direct ['] emit defer@  old-emit !  ['] putc is emit ;
: end-direct   old-emit @ is emit ;

( position management )
variable top     ( byte offset )
variable topline ( row numbering starts at 1 )

( row and col store the actual position of the cursor )
( vcol is the column the cursor "wants" to be at, and to which it will )
( move to when it arrives at a line long enough to allow it )
variable row
variable col     ( column numbering starts at 0 )
variable vcol

: go-top  0 top !  1 topline !  1 row !  0 col !  0 vcol ! ;
: read-file  read-file go-top ;

: #lines ( -- u ) 0 #buf @ 0 ?do i b@ #lf = if 1+ then loop ;
: buf?  ( b -- ? ) #buf @ u< ;
: skip-line ( b -- b ) begin dup buf? while dup b@ #lf =
  if 1+ exit then 1+ repeat ;
: >line ( u -- b )  0 swap 1 ?do skip-line loop ;
: cr>pos ( col row -- b ) >line + ;
: >pos  ( -- b ) col @ row @ cr>pos ;

( cursor positioning )
: col! ( u -- ) dup col ! vcol ! ;
: line-length ( b -- u ) dup begin dup buf?
  if dup b@ #lf <> else false then while 1+ repeat swap - ;
: apply-vcol ( -- ) row @ >line line-length vcol @ umin  col ! ;
: defuse-vcol ( -- ) apply-vcol col @ vcol ! ;

: fixpos ( -- ) row @ 0= if 1 row ! 0 col ! then
  row @ #lines > if #lines row ! then
  apply-vcol ;
: top! ( u -- ) dup topline ! >line top ! ;
: row! ( u -- ) 1 max #lines min row ! ;

( rendering )
variable rrow   variable rcol ( buffer-space renderer position )

( if we're where the cursor is supposed to be, put it here )
variable has-curpos
: curpos? ( -- ) rrow @ row @ = rcol @ col @ = and if
    cy @ 8 lshift cx @ + curpos!
    has-curpos on
  then ;

variable margin
: size-margin ( -- ) #lines 0 <# #s #> margin ! drop ;
: .margin ( -- ) begin-direct gray  rcol @ if margin @ spaces
  else rrow @ margin @ u.r then space noclr end-direct ;
: margin? ( -- ) cx @ 0= if .margin then ;
: next-line ( -- ) fill-line  0 rcol !  1 rrow +!  newline ;
: newline? ( -- ) line-space? invert if newline then margin? ;
: normal-char ( c -- ) putc 1 rcol +! ;
: bget ( b -- b c ) dup 1+ swap b@ ;
: render-char ( b -- b ) newline? curpos? bget dup #lf =
  if drop next-line else normal-char then ;

variable need-status
: status ( -- ) #24 cy ! 0 cx !  begin-direct need-status off ;
: end-status    end-direct fill-line ;

: render ( -- )
  topline @ rrow !  0 rcol !
  0 cx !  0 cy !
  has-curpos off
  size-margin
  .margin top @ begin
    dup buf? editor-space? and
  while render-char repeat
  drop fill-rest  need-status on ;

( make sure the cursor isn't above the screen )
( when it is below, try to avoid scrolling for a long time )
: fixtop-above ( -- ) row @ topline @ < if row @ top! then ;
: fixtop-below ( -- ) topline @ #25 + row @ < if row @ #25 - top! then ;
: fixtop ( -- ) fixpos  fixtop-above  fixtop-below ;

( if there's no cursor, scroll down until there is )
: render   fixtop begin render has-curpos @ invert while
  topline @ 1+ top! repeat ;

( keymaps )
variable rcnt   0 rcnt !

value keypress
: ctrl  char $1F and ;
: keymap  create  ' , $100 cells callot
  does> keypress lobyte 1+ cells over + @
  dup if nip else drop @ then execute ;
: >>  latest @ >xt ;
: (bind) ( xt c keymap-xt -- ) >r 1+ cells r> >body + ! ;
: bind ( xt c " keymap" -- ) ' (bind) ;
: unbound ( -- ) 0 rcnt !
  status ." Unbound key " keypress 4 u.r end-status ;

keymap movement unbound
keymap normal movement
: current-keymap normal ;

keymap gprefix unbound
: do-gprefix ( -- ) key to keypress  gprefix ; >> char g bind movement

defer modeline
: handle-key  key to keypress  ['] current-keymap catch
  dup if status red execute end-status else drop then ;
: modeline?  need-status @ if status modeline end-status then ;
: edit-loop  decimal begin render handle-key ensure-eol modeline? again ;
: quit-editor  clrscr quit ; >> char Q bind normal

( modeline )
: normal-modeline ( -- )
  ." Editing " buf-filename count type
  ."  (" #buf @ u. ." bytes"
  dirty @ if ." ; dirty" then
  ." )" ;
: normal-mode ['] normal-modeline is modeline
              ['] normal is current-keymap
  0 rcnt ! ;
normal-mode

( operators )
variable operator   0 operator !
variable opchar

( store col first so that ud< will compare positions correctly )
2variable pos1  2variable pos2
: rc! ( addr -- ) >r col @ row @ r> 2! ;
: op-range ( -- b u ) pos1 2@ cr>pos  pos2 2@ cr>pos  over - ;
: sort-pos ( -- ) pos1 2@ pos2 2@ ud> if
  pos1 2@ pos2 2@ pos1 2! pos2 2! then ;

: apply-operator ( -- )
  operator @ if
    normal-mode
    op-range operator @ execute
    0 operator !
    pos1 2@ row ! col!
  then ;

: after-move ( -- ) pos2 rc!  sort-pos ;

variable is-linewise
: exclusive ( -- ) is-linewise off  after-move apply-operator ;
: inclusive ( -- ) is-linewise off  after-move 1 pos2 +! apply-operator ;
: linewise ( -- )  is-linewise on
  apply-vcol after-move 
  0 pos1 ! ( snap to beginning of line )
  0 pos2 ! 1 pos2 cell+ +! ( snap to beginning of next line )
  apply-operator ;

: operator-pending ( -- )
  keypress lobyte opchar @ = if linewise else movement then ;

: defop ( xt -- xt c )
  create , char dup , >> swap
  does> ( -- ) 2@ opchar ! operator !
  pos1 rc!
  ['] operator-pending is current-keymap ;

( repeat count )
: bind-digits ( xt -- ) [char] 0 begin
    dup [char] 9 <=
  while 
    2dup ['] movement (bind)
  1+ repeat 2drop ;
: >digit ( c -- u ) lobyte [char] 0 - ;
: rcnt-digit ( -- ) rcnt @ #10 u* keypress >digit + rcnt ! ;
  >> bind-digits
: repeats ( -- u ) rcnt @ dup 0= if drop 1 then  0 rcnt ! ;

( movement )
: up   row @ repeats - row! linewise ;
  >> char k bind movement
: down row @ repeats + row! linewise ;
  >> char j bind movement
: left  col @ repeats - 0 max col! exclusive ;
  >> char h bind movement
: right col @ repeats + row @ >line line-length min col! exclusive ;
  >> char l bind movement

: lbegin  0 col! exclusive ;
: bind0  rcnt @ 0= if lbegin else rcnt-digit then ;
  >> char 0 bind movement
: lend    -1 vcol ! apply-vcol exclusive ;
  >> char $ bind movement

( buffer modification )
: out-of-space ." out-of-space" ;
: has-space ( u -- ) #buf @ + #buf @ u<
  ['] out-of-space and throw ;
: (make-space) ( b u -- u ) swap #buf @ 1- do
  i b@ over i + b! -1 +loop ;
: make-space ( b u -- ) dup has-space
  over #buf @ < if (make-space) else nip then
  #buf +! mark ;
: buf-rest ( b -- b u ) #buf @ over - ;
: delete-range ( b u -- ) dup >r  over + swap buf-rest
  (buf) fs-cmove  r> negate #buf +! mark ;

( insert mode )
: (insert-char) ( c -- ) >pos dup 1 make-space b! ;
: insert-char keypress lobyte dup printable? if
  (insert-char) right else drop unbound then ;
keymap insert insert-char
: insert-modeline ." -- INSERT --" ;
: insert-mode ['] insert-modeline is modeline
  ['] insert is current-keymap ; >> char i bind normal

' normal-mode #esc bind insert
: move-left ( -- ) col @ 0<> if left else up lend then ;
: delete-before ( -- ) >pos dup 0<> if move-left defuse-vcol
  1- 1 delete-range else drop then ;
  >> char X bind normal
  >> #bs bind insert
: delete-after ( -- ) >pos 1 delete-range ;
  >> char x bind normal
: enter ( -- ) #lf (insert-char) down lbegin ;
  >> #cr bind insert

( ways of entering insert mode )
: prepend    lbegin insert-mode ; >> char I bind normal
: append-lend  lend insert-mode ; >> char A bind normal
: append      right insert-mode ; >> char a bind normal
: insert-above  lbegin #lf (insert-char) insert-mode ;
  >> char O bind normal
: insert-below  lend enter insert-mode ; >> char o bind normal

( user-facing commands )
' save char Z bind normal
Forth definitions
: fed edit-loop ;
: fedit read-file edit-loop ;
previous previous Fed definitions

( paste buffer )
create #paste 0 ,
variable paste-linewise
: (pbuf)  $2000 fs! ;
: pb@  (pbuf) farc@ ;
: pb!  (pbuf) farc! ;

: copy-range ( b u -- ) dup #paste !
  0 ?do dup i + b@ i pb! loop  drop ;

: (yank) copy-range  is-linewise @ paste-linewise ! ;
  >> defop yank y bind normal
: (delete) 2dup copy-range  delete-range
  is-linewise @ paste-linewise ! ;
  >> defop delete d bind normal
: (change) (delete) is-linewise @ if insert-above else insert-mode then ;
  >> defop change c bind normal

: paste-at ( b -- ) dup #paste @ make-space
  #paste @ 0 ?do i pb@ over i + b! loop drop ;

: paste-before  paste-linewise @ if lbegin then >pos paste-at ;
  >> char P bind normal
: paste-after   paste-linewise @ if
    row @ 1+ >line
  else
    >pos 1+
  then paste-at ;
  >> char p bind normal

( turn a byte position into row,col again )
: pos! ( b -- ) 0 swap 0 begin ( row b brow ) 2dup >= while skip-line
  2>r 1+ 2r> repeat drop over row ! swap >line - col! ;

( simple movements )
: first-line ( -- ) 1 row ! 0 col! linewise ; >> char g bind gprefix
: go-to-line ( -- ) rcnt @ 0= if #lines else repeats then
  row ! 0 col! linewise ; >> char G bind movement
: screen-up ( -- )
  topline @ #12 - 1 max top!
  row @ #12 - 1 max row !
  linewise ; >> ctrl u bind movement
: screen-down ( -- )
  topline @ #12 + #lines min top!
  row @ #12 + #lines min row !
  linewise ; >> ctrl d bind movement
: top-line ( -- ) topline @ row ! 0 col! linewise ; >> char H bind movement

( word-wise movements )
: ws? ( c -- t|f ) dup #bl = swap #lf = or ;
: word? ( c -- t|f ) ws? invert ;
: word-begin? ( b -- ) dup 0= if true else dup 1- b@ ws? then
  ( b prev-ws ) swap b@ word? and ;
: word-end? ( b -- ) dup 1+ buf? if dup 1+ b@ ws? else true then
  ( b next-ws ) swap b@ word? and ;
defer ok?

: scan-fwd ( pos -- pos found? )
  begin 1+ dup buf? while
    dup ok? if true exit then
  repeat 1- false ;
: scan-bck ( pos -- pos found? )
  begin 1- dup buf? while
    dup ok? if true exit then
  repeat 1+ false ;

: word-fwd ( -- ) ['] word-begin? is ok?
  >pos scan-fwd drop pos! exclusive ;
  >> char w bind movement >> char W bind movement
: word-bck ( -- ) ['] word-begin? is ok?
  >pos scan-bck drop pos! exclusive ;
  >> char b bind movement >> char B bind movement
: wend-fwd ( -- ) ['] word-end? is ok?
  >pos scan-fwd drop pos! inclusive ;
  >> char e bind movement >> char E bind movement

( scan for character )
: is-char? ( b -- ) b@ keypress lobyte = ;
: char-fwd ( -- ) key to keypress  ['] is-char? is ok?
  >pos scan-fwd if pos! exclusive then ; >> char f bind movement
: char-bck ( -- ) key to keypress  ['] is-char? is ok?
  >pos scan-bck if pos! exclusive then ; >> char F bind movement
: till-fwd ( -- ) key to keypress  ['] is-char? is ok?
  >pos scan-fwd if 1- pos! inclusive then ; >> char t bind movement
: till-bck ( -- ) key to keypress  ['] is-char? is ok?
  >pos scan-bck if 1+ pos! exclusive then ; >> char T bind movement

( search )
create searchtext 80 allot

: search-modeline ( -- ) [char] / emit
  searchtext count type ;
: search-insert-char ( -- ) keypress lobyte dup printable? if
    searchtext count + c!
    searchtext c@  1+  searchtext c!
  else drop unbound then ;

keymap search search-insert-char

: search-mode ( -- )
  0 searchtext c!
  ['] search-modeline is modeline
  ['] search is current-keymap ; >> char / bind normal
' normal-mode #esc bind search
: search-backspace ( -- ) searchtext c@ dup if
    1- searchtext c!
  else drop normal-mode then ; >> #bs bind search
( reading past #buf is harmless here because the search term won't )
( contain the buffer's trailing newline ;3 )
: is-match? ( b -- )
  searchtext count 0 ?do
    over b@ over c@ <> if
      2drop unloop false exit
    then
    swap 1+ swap 1+
  loop 2drop true ;
: next-match ( -- ) ['] is-match? is ok?
  >pos scan-fwd if pos! else drop
    status ." No match" end-status
  then ;
  >> char n bind normal
: search-enter ( -- ) normal-mode next-match ;
  >> #cr bind search

previous definitions
