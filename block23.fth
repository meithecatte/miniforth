( vocabularies )
10 stack search-order
create current latest ,         :noname current @ ; is latest
: (vocabulary) create 0 , latest @ , does> search-order push ;
: unlink ( wid -- nt ) dup @ tuck @ swap ! ;
: relink ( nt wid -- ) 2dup @ swap ! ! ;
: move-to ( wid -- ) latest unlink swap relink ;
: definitions ( -- ) search-order peek current ! ;
(vocabulary) Root  (vocabulary) Forth  Root Forth
latest @ ' Forth >body !  definitions
' Root >body  dup dup move-to move-to move-to




                                                             -->
