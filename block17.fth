( >number )
: within ( n lo hi -- f|t ) over - >r - r> u< ;
: digit ( c -- f | v t )
  dup [char] 0 [char] 9 1+ within if [char] 0 - else
  dup [char] A [char] Z 1+ within if [char] A - A + else
  dup [char] a [char] z 1+ within if [char] a - A + else
  drop false exit then then then
  dup base @ < if true else drop false then ;
: basechar ( c -- base | 0 ) case
  [char] # of A endof       [char] $ of 10 endof
  [char] % of 2 endof       dup of 0 endof  endcase ;
: on true swap ! ;  : off false swap ! ;  variable is-dnum
: >digits ( str -- str' ud' ) 0 0 2>r  begin dup while
  over c@  [char] . = if  1 /string  is-dnum on  else
  over c@  digit if s>d 2r> base @ ud*u d+ 2>r  1 /string else
  2r> exit then then repeat 2r> ;                            -->
