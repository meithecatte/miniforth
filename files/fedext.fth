Fed definitions

( run part of file )
: run-from ( -- ) save >pos s>d buf-filename count (exec) ;
  >> char r bind gprefix

( paste block from block editor )
: paste, ( c -- ) #paste @ pb! 1 #paste +! ;
: spaste, ( s u -- ) 0 ?do dup i + c@ paste, loop drop ;
: rtrim ( s u -- s u ) begin
    dup 0<> if 2dup + 1- c@ #bl = else false then
  while 1- repeat ;
: paste-block ( -- ) 0 #paste !  $1000 $c00 ?do
    i $40 rtrim tuck .s spaste,
    $40 <> if #lf paste, then
  $40 +loop paste-linewise on ;
: paste-block-before  paste-block paste-before ; >> char P bind gprefix
: paste-block-after   paste-block paste-after ;  >> char p bind gprefix

previous definitions
