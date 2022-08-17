( editor: rendering - cont. )
defer modeline
: modeline-normal ." Editing block $" curblk .
  dirty @ if ."  (dirty)" then ;
' modeline-normal is modeline
: (curpos)  row @ $100 u* col @ 3 + + curpos! ;
: (render) buf  #lines 0 ?do show-line loop  drop ;
variable need-redraw
( split rendering into the part before and after the modeline
  -- allows displaying a message by: status ." ..." )
: status ( -- ) clrscr (render) white  need-redraw off ;
: ,s ( -- ) status .s ;
: render ( --) need-redraw @ if status modeline then (curpos) ;
                                                             -->


