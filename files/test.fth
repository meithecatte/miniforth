( test case syntax )
vocabulary Tester
Tester definitions

$10 constant bufsize
create buf bufsize cells allot
variable buf-elems

exception end-exception test-overflow
exception end-exception test-underflow

variable depth0
: rel-depth ( -- u )
  depth depth0 @ -
  dup 0< ['] test-underflow and throw ;
: to-depth0 ( -- ) rel-depth 0 ?do drop loop ;

: report-failure ( -- ) cr
  ." test failed" cr
  .input
  ." expected: "
  rel-depth if rel-depth 1- 0 swap do
    i pick .
  -1 +loop then cr
  ."      got: "
  buf-elems @ if buf-elems @ 1- 0 swap do
    buf i cells + @ .
  -1 +loop then cr ;

: match? ( ? -- ? )
  rel-depth 0 ?do
    i pick buf i cells + @ <> if
      report-failure leave
    then
  loop ;

Forth definitions

: t{ ( -- )
  depth depth0 ! ;

: >-> ( ? -- )
  rel-depth dup bufsize > ['] test-overflow and throw
  dup buf-elems !
  0 ?do
    i pick buf i cells + !
  loop
  to-depth0 ;

: }t ( ? -- )
  rel-depth buf-elems @ <> if report-failure else match? then
  to-depth0 ;

previous previous definitions
