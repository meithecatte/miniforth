( structured exceptions )
: exception ( -- dict-pos ) latest @ ;
: print-uint @ u. ; : uint ['] print-uint , variable ;
: print-str 2@ type ; : str ['] print-str , 2variable ;
: print-name, ( nt -- ) >name postpone{ 2literal type } ;
: print-field, ( nt -- )
  dup print-name, postpone space
  dup >xt ,
  1 cells - @ ,
  postpone cr ;
: end-exception ( dict-pos -- ) latest @
  :  latest @ print-name,  postpone cr
  begin ( end-pos cur-pos ) 2dup <> while
    dup print-field,  @
  repeat  2drop  postpone ;  ;
                                                             -->
