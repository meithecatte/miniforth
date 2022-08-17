( key accept )
:code key  bx push, ax ax xorw-rr, 16 int, ax bx movw-rr, next,
8 constant #bs   D constant #cr   A constant #lf
: printable? dup 20 >= swap 7E <= and ;
: append ( str len c -- str len+1 ) >r 2dup + r> swap c! 1+ ;
: unemit  #bs emit  space  #bs emit ;
: accept ( buf max-len -- buf len ; stores max-len on rstack )
  >r 0  begin ( buf cur-len )
    key FF and ( TODO: how to handle extended keys )
    dup printable? if
      over r@ < if  dup emit append  else drop then
    else case
      #cr of  rdrop exit  endof
      #bs of  dup 0<> if  1 -  unemit  then  endof
    endcase then
  again ;                                                    -->
