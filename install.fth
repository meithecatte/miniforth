( install to other disk )
value target
$2000 constant buffer    $4000 #512 u/ constant bufsize
: read-orig  target 0. 1 buffer dread ;
: read-ours  disk#  0. 1 buffer $200 + dread ;
: copy-code  buffer $200 + buffer #446 cmove ;
: write-back target 0. 1 buffer dwrite ;
: copy-mbr   read-orig read-ours copy-code write-back ;
: copy-small ( lo count -- ) 2dup 2>r 2>r
  disk#  2r> 0 swap buffer dread
  target 2r> 0 swap buffer dwrite ;
: copy-rest ( lo count -- ) begin dup while
  2dup bufsize min copy-small  dup bufsize min tuck - >r + r>
  repeat ;
: install-to ( sectors disk -- ) to target copy-mbr
  1- 1 swap copy-rest ;
