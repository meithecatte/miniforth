( random words not defined earlier )
: max ( a b -- m ) 2dup < if nip else drop then ;
: min ( a b -- m ) 2dup > if nip else drop then ;
: shlw-cl,  D3 c, 4 rm-r, ;
:code lshift  bx cx movw-rr, bx pop, bx shlw-cl, next,
: ud> ( da db -- da>db ) >r swap r> 2dup <> if 2swap then 2drop
  u> ;









