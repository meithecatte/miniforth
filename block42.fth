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
$1B constant #esc  ' normal-mode #esc bind insert
:noname ." -- INSERT --" ; : insert-mode literal is modeline
  ['] insert is current-keymap ;
' insert-mode  char i bind normal                            -->
