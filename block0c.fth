( exception handling )

:code sp! bx sp movw-rr, bx pop, next,
:code rp@ bx push, di bx movw-rr, next,
:code rp! bx di movw-rr, bx pop, next,
:code execute bx ax movw-rr, bx pop, ax jmp-r,
variable catch-rp
: catch ( i*x xt -- j*x 0 | i*x n )
  sp@ >r  catch-rp @ >r
  rp@ catch-rp !
  execute 0
  r> catch-rp ! rdrop ;
: throw  dup if
  catch-rp @ rp!  r> catch-rp !
  r> swap >r sp!  drop ( the xt slot )  r>
else drop then ;                                             -->
