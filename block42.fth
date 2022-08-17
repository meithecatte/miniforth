( editor: basic movement )
: quit-editor status quit ; >> char Q bind normal
: move-left  col @ 1- 0   max col ! ; >> char h bind normal
: move-right col @ 1+ $3f min col ! ; >> char l bind normal
: move-up    row @ 1- 0   max row ! ; >> char k bind normal
: move-down  row @ 1+ $f  min row ! ; >> char j bind normal
: move-begin 0 col ! ;                >> char 0 bind normal
: move-top   0 row ! move-begin ;     >> char H bind normal
: move-bot   $f row ! move-begin ;    >> char L bind normal
: move-prev  curblk 1- read ;         >> char [ bind normal
: move-next  curblk 1+ read ;         >> char ] bind normal




                                                             -->
