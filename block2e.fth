( editor: line insert )
buf #lines 1- line-length u* +  constant last-line
: not-bottom ( -- ) row @ #lines 1- >=
  ['] won't-fit-in-buffer and throw ;
: has-empty ( -- )
  last-line line-length 0 do dup c@ is#bl 1+ loop  drop ;
: how-much ( addr -- count ) last-line swap - ;
: insert-line ( addr -- ) has-empty dup dup line-length +
  over how-much move  line-length clear  mark ;
: line-above  move-begin cur>buf insert-line ;
: line-below  not-bottom move-down line-above ;
: insert-above line-above insert-mode ; >> char O bind normal
: insert-below line-below insert-mode ; >> char o bind normal
: split-line cur>buf line-below cur>buf 2dup 2dup swap - move
  over - clear ;  >> #cr bind insert
                                                             -->
