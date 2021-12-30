( search-order support for find )
:noname ( name len -- nt|0 ) search-order stk.iter< do
  2dup i @ search-in  dup if >r 2drop r> unloop exit then
  drop <next 2drop 0 ; is find
: vocabulary (vocabulary) [ ' Root >body ] literal move-to ;
: vocab. cell+ @ >name type ;
Root definitions
: previous search-order pop drop  search-order stk.depth 0= if
  Root then ;
: order search-order stk.iter> ?do i @ vocab. space >next
  space current @ vocab. ;
previous definitions

