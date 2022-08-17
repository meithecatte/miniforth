( >number )
: [within] char char 1+ postpone{ 2literal within } ; immediate
: digit ( c -- f | v t ) dup [within] 0 9 if [char] 0 - else
  dup [within] A Z if [char] A - A + else
  dup [within] a z if [char] a - A + else
  drop false exit then then then
  dup base @ < if true else drop false then ;
: basechar ( c -- base | 0 ) case
  [char] # of A endof       [char] $ of 10 endof
  [char] % of 2 endof       dup of 0 endof  endcase ;
: on true swap ! ;  : off false swap ! ;  variable is-dnum
: >digits ( str -- str' ud' ) 0 0 2>r  begin dup while
  over c@  [char] . = if  1 /string  is-dnum on  else
  over c@  digit if s>d 2r> base @ ud*u d+ 2>r  1 /string else
  2r> exit then then repeat 2r> ;
                                                             -->
