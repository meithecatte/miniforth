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
