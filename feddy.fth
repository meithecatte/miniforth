( file editor -- buffer management )
vocabulary Fed  Fed definitions
: (buf) $1000 fs! ;  : b@ (buf) farc@ ; : b! (buf) farc! ;
variable #buf      variable dirty   : mark  dirty on ;
variable buf-cwd   create buf-filename $80 allot
: filename! ( name len -- ) dup buf-filename c!
  >r buf-filename 1+ r> cmove ;
: cappend ( c -- ) #buf @ b! 1 #buf +! ;
: sappend ( s u -- ) over + swap ?do i c@ cappend loop ;
exception var filename: end-exception file-too-large
: #read  bytes-left d>s $1000 umin ;
: (read) ( -- ) fsize 2@ 0<> ['] file-too-large and throw drop
  begin fneof? while $1000 #read dup >r fread
  $1000 r> sappend repeat ;                                  -->


( file editor -- read-file )
: eol? ( -- ? ) #buf @ if #buf @ 1- b@ #lf = else false then ;
: ensure-eol ( -- ) eol? invert if #lf cappend mark then ;
: read-file ( name len -- ) cwd buf-cwd !  2dup filename!
  0 #buf !  fopen? if (read) dirty off then ensure-eol ;
: prepare-buf ( b len -- ) $1000 swap 0 ?do over b@ over c!
  1+ swap 1+ swap loop 2drop ;
: #write ( b -- b u ) #buf @ over - $1000 umin ;
: (save) ( -- ) buf-cwd @ cwds push  buf-filename count fcreate
  0 begin dup #buf @ < while dup #write dup >r prepare-buf
  $1000 r@ fwrite r> + repeat drop undirty  cwds pop drop ;
: save ( -- ) dirty @ if (save) dirty off then ;             -->




( file editor -- direct to VGA )
variable cx     variable cy
: line-space?  cx @ #80 < ;     : screen-space?  cy @ #25 < ;
: editor-space?  cy @ #24 < ;
: >vga ( -- addr ) cy @ #80 u*  cx @ + 2* ;
: putc ( c -- ) >vga dup >r vga!  color @ r> 1+ vga!  1 cx +! ;
: puts ( s u -- ) 0 ?do dup c@ putc 1+ loop drop ;
: newline ( -- ) 0 cx !  1 cy +! ;
: fill-line ( -- ) begin line-space? while #bl putc repeat ;
: fill-rest ( -- ) begin editor-space? while
  fill-line newline repeat ;
variable old-emit
: begin-direct ['] emit defer@  old-emit !  ['] putc is emit ;
: end-direct   old-emit @ is emit ;                          -->


( file editor -- position management )
variable top    variable topline
variable row    variable col    variable vcol
: go-top  0 top !  1 topline !  1 row !  0 col !  0 vcol ! ;
: read-file  read-file go-top ;
variable rrow   variable rcol   variable has-curpos
: begin-render ( -- ) topline @ rrow !  0 rcol !
  0 cx ! 0 cy ! has-curpos off ;
: curpos? ( -- ) rrow @ row @ = rcol @ col @ = and if
  cy @ 8 lshift cx @ + curpos!  has-curpos on then ;

: buf?  ( b -- ? ) #buf @ u< ;
: skip-line ( b -- b ) begin dup buf? while dup b@ #lf =
  if 1+ exit then 1+ repeat ;
: >line ( u -- b )  0 swap 1 ?do skip-line loop ;
: >pos  ( -- b ) row @ >line  col @ + ;                      -->
( file editor -- rendering )
variable margin  2 margin !  variable need-status
: .margin begin-direct gray  rcol @ if margin @ spaces
  else rrow @ margin @ u.r then space noclr end-direct ;
: margin? ( -- ) cx @ 0= if .margin then ;
: next-line ( -- ) fill-line  0 rcol !  1 rrow +!  newline ;
: newline? ( -- ) line-space? invert if newline then margin? ;
: normal-char ( c -- ) putc 1 rcol +! ;
: bget ( b -- b c ) dup 1+ swap b@ ;
: render-char ( b -- b ) newline? curpos? bget dup #lf =
  if drop next-line else normal-char then ;
: status ( -- ) #24 cy ! 0 cx !  begin-direct need-status off ;
: end-status    end-direct fill-line ;
: render ( -- ) begin-render .margin top @ begin dup buf?
  editor-space? and while render-char repeat drop fill-rest
  need-status on ;                                           -->
( file editor -- cursor positioning )
: col! ( u -- ) dup col ! vcol ! ;
: #lines ( -- u ) 0 #buf @ 0 ?do i b@ #lf = if 1+ then loop ;
: fixpos ( -- ) row @ 0= if 1 row ! 0 col ! then
  >pos buf? invert if 0 col! #lines row ! then ;
: top! ( u -- ) dup topline ! >line top ! ;
: line-length ( b -- u ) dup begin dup buf?
  if dup b@ #lf <> else false then while 1+ repeat swap - ;
: fixtop ( -- ) row @ topline @ < if row @ top! then ;
: render   fixtop begin render has-curpos @ invert while
  topline @ 1+ top! repeat ;
: apply-vcol ( -- ) row @ >line line-length
  vcol @ umin  col ! ;
: defuse-vcol ( -- ) apply-vcol col @ vcol ! ;
                                                             -->

( file editor -- keymaps )
value keypress                  : ctrl  char $1F and ;
: keymap  create  ' , $100 cells callot
  does> keypress lobyte 1+ cells over + @
  dup if nip else drop @ then execute ;
: >>  latest @ >xt ;
: bind  1+ cells ' >body + ! ;
: unbound  status ." Unbound key " keypress 4 u.r end-status ;
keymap movement unbound
keymap normal movement
: current-keymap normal ;     : modeline ;
: handle-key  key to keypress  ['] current-keymap catch
  dup if status red execute end-status else drop then ;
: modeline?  need-status @ if status modeline end-status then ;
: edit-loop  decimal begin render handle-key modeline? again ;
: quit-editor  clrscr quit ; >> char Q bind normal           -->
( file editor -- movement )
: linewise  apply-vcol ;  : inclusive ;  : exclusive ;
: up   row @ 1-      1 max row ! linewise ;
  >> char k bind movement
: down row @ 1+ #lines min row ! linewise ;
  >> char j bind movement
: left  col @ 1- 0 max col! exclusive ; >> char h bind movement
: right col @ 1+ row @ >line line-length min col!
  inclusive ; >> char l bind movement

: lbegin  0 col! exclusive ; >> char 0 bind movement
: lend    -1 vcol ! apply-vcol exclusive ;
  >> char $ bind movement                                    -->



( file editor -- modeline )
: normal-modeline  ( -- ) ." Editing " buf-filename count type
  ."  (" #buf @ u. ." bytes"  dirty @ if ." ; dirty" then
  ." )" ;
: normal-mode ['] normal-modeline is modeline
              ['] normal is current-keymap ;
normal-mode                                                  -->









( file editor -- buffer modification )
: out-of-space ." out-of-space" ;
: has-space ( u -- ) #buf @ + #buf @ u<
  ['] out-of-space and throw ;
: make-space ( b u -- ) dup has-space  swap #buf @ 1- do
  i b@ over i + b! -1 +loop  #buf +! mark ;
: buf-rest ( b -- b u ) #buf @ over - ;
: delete-range ( b u -- ) dup >r  over + swap buf-rest
  (buf) fs-cmove  r> negate #buf +! mark ;
                                                             -->






( file editor -- insert mode )
: insert-char keypress lobyte dup printable? if
  >pos dup 1 make-space b! right else drop unbound then ;
keymap insert insert-char
: insert-modeline ." -- INSERT --" ;
: insert-mode ['] insert-modeline is modeline
  ['] insert is current-keymap ; >> char i bind normal
' normal-mode #esc bind insert
: move-left col @ 0<> if left else up lend then ;
: delete-before >pos dup 0<> if move-left defuse-vcol
  1- 1 delete-range else drop then ; >> char X bind normal
  >> #bs bind insert
: enter >pos dup 1 make-space #lf swap b! down lbegin ;
  >> #cr bind insert                                         -->


( file editor -- user-facing commands )
' save char Z bind normal
Forth definitions
: fed edit-loop ;
: fedit read-file edit-loop ;
previous previous definitions










