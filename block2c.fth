( editor: remove character )
: shift-back dup 1+ swap dup how-much move ;
: remove-at ( a -- ) dup shift-back line-end #bl swap c! mark ;
: remove-right cur>buf remove-at ; >> char x bind normal
: remove-left move-left remove-right ; >> char X bind normal
                                       >> #bs bind insert









                                                             -->
