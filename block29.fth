( counted loops cont. )
: jo, 70 c, ;   : jno, 71 c, ;  : subw-ir, 81 c, 5 rm-r, , ;
:code (+loop)   ( shift everything st upper-limit = $8000 )
  -2 cells [di] dx movw+mr,  $8000 dx subw-ir,
  -1 cells [di] cx movw+mr,  dx cx subw-rr,
  bx cx addw-rr, bx pop,
  lodsw, jo, j>
    ax si movw-rr,
    dx cx addw-rr,  -1 cells cx [di] movw+rm,
  >j next,
: +loop postpone (+loop) end-loop ; immediate
: loop 1 lit, postpone +loop ; immediate



                                                             -->
