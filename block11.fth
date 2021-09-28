( postpone postpone{ )
: (postpone) ( str -- ) must-find dup immediate? invert
  if compile compile then   >xt , ;
: postpone  #bl token (postpone) ; immediate
: postpone{ begin #bl token 2dup s" }" s= invert while
  (postpone) repeat 2drop ; immediate









                                                             -->
