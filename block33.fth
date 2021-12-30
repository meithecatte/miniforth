( coloring helpers )
: color: ( n -- ) create , does> @ color ! ;
: colors:  0 begin dup $10 < while dup color: 1+ repeat drop ;
colors: black blue green cyan red purple brown noclr
        gray lblue lgreen lcyan lred lpurple yellow white
: refill-kbd white refill-kbd noclr ;   ' refill-kbd is refill









                                                             -->
