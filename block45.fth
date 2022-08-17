( editor: user-facing commands )
Forth definitions
: ed edit-loop ;
: edit read ed ;
: save save ;
: run  save curblk load ;
: bnew status ." Erase this block? (y/n)" key lobyte
  [char] y = if buf 400 clear mark move-top then ed ;
previous definitions
                                                             -->






