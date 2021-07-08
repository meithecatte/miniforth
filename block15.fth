( case )
: case 0 ; immediate
: (of) ( a b -- skip: a | cont: )
  over = if
    drop r> cell+ >r
  else
    r> @ >r
  then ;
: of postpone (of) br> ; immediate
: endof >r postpone (branch) br> r> >br ; immediate
: endcase  postpone drop
  begin dup while >br repeat drop ; immediate



                                                             -->
