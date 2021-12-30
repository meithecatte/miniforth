( does>  /  structures )
: >exit ( nt -- @exit ) >xt [ 3 2 cells + ] literal + ;
: >body ( xt -- body ) [ 3 3 cells + ] literal + ;
: does, here 6 + si movw-ir, next, ;
: (does>) r> latest @ >exit ! ;
: does> postpone (does>) does, ; immediate

: +field ( off sz -- off ) create over , + does> @ + ;
: field:  1 cells +field ;      : cfield: 1 +field ;
: 2field: 2 cells +field ;





                                                             -->
