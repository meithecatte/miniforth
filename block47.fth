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
