( quit )
: ."  postpone s"  compiling? if postpone type else type then
  ; immediate
: refill-kbd 0 500 dup >in ! 100 accept + c!  space ;
: refill ;
: prompt cr space depth u. compiling? if ."  compiled" else
  ."  ok" then ." > " ;
: repl begin refill interpret prompt again ;
:noname 1 st c! ; is [          :noname 0 st c! ; is ]
rp@ constant r0
: quit begin postpone [  r0 rp!
  ['] repl catch  cr execute again ;
:noname ; is skip-space
: list cr list ;
quit            ' refill-kbd is refill
                                                             -->
