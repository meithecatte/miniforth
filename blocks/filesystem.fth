( more flexible disk I/O )
: dpacket ( dLBA count buf -- )
  packet pos !
  10 pos, ( magic )
  swap pos, ( count )
  pos, 0 pos, ( buffer )
  swap pos, pos, 0 pos, 0 pos, ( LBA ) ;
:code do-int13 ( disk ax -- err? )
  dx pop,  si push, packet si movw-ir,
  bx ax movw-rr, $13 int,
  ax bx movw-rr,  si pop, next,
: dread ( disk dLBA count buf -- ) dpacket 4200 do-int13 err? ;
: dwrite ( as above ) dpacket 4300 do-int13 err? ;
                                                             -->


( partition table and chainloading )
: load-ptable 0 $1c00 read-block ;
: ptable $1c00 #446 + ;
: part ( u -- ptr ) $10 u* ptable + ;
: part-start ( n -- dLBA ) part 8 + 2@ ;
: part-size  ( n -- d )    part c + 2@ ;
: ret, $C3 c, ;      $2000 constant buffer
: chainload ( n -- ) >r load-ptable
  disk# r> part-start 1 buffer dread
  buffer $1FE + @ $AA55 = if
    $600 dp !  $6000 sp movw-ir,
    buffer si movw-ir, $7C00 di movw-ir, $200 cx movw-ir,
    rep, movsb, disk# dl movb-ir, $7C00 bx movw-ir, bx push,
    ret,
    $600 execute
  else ." Invalid signature" cr then ;                       -->
( filesystem -- 4k blocks, free/used bitmap )
vocabulary Files     Files definitions
2variable lba0  load-ptable     0 part-start lba0 2!
: >lba ( blk -- dLBA ) 0 8 ud*u lba0 2@ d+ ;
: bread ( blk buf -- ) >r >r disk# r> >lba 8 r> dread ;
: bwrite ( blk buf -- ) >r >r disk# r> >lba 8 r> dwrite ;
$2000 constant freebits         0 freebits bread
: (>bit) ( #bit -- val offset ) 8 u/mod >r 1 swap lshift r> ;
: >bit ( #bit -- val addr ) (>bit) freebits + ;
: is-free ( blk -- ? ) >bit c@ and 0= ;
: save-bits ( -- ) 0 freebits bwrite ;
: (mark-free) ( blk -- ) >bit dup >r c@ swap invert and r> c! ;
: (mark-used) ( blk -- ) >bit dup >r c@ or r> c! ;           -->



( filesystem -- freebits manipulation )
: mark-free ( -- )  (mark-free) save-bits ;
: mark-used ( -- )  (mark-used) save-bits ;
: format-freebits ( -- )        load-ptable
  freebits $1000 0 fill         0 (mark-used)
  0 part-size 8 ud/mod d>s nip
  $8000 swap ?do i (mark-used) loop save-bits ;
exception end-exception out-of-space
: alloc-any ( -- blk ) $8000 0 ?do
  i is-free if i unloop exit then loop ['] out-of-space throw ;
: alloc-sparse ( -- blk ) freebits dup $1000 + swap ?do
  i @ 0= if i freebits - 8 u* unloop exit then 2 +loop
  alloc-any ;
: alloc-after ( blk -- blk ) 1+ dup is-free invert
  if drop alloc-sparse then ;
                                                             -->
( filesystem -- blocklist: blk blk blk ... 0 0 0 ... fsize )
exception end-exception no-file-open   create cur-fid 0 ,
: fid? ( -- ) cur-fid @ 0= ['] no-file-open and throw ;
$3000 constant blks             $3FFC constant fsize
: save-blks ( -- ) fid? cur-fid @ blks bwrite ;
: open-fid ( fid -- ) dup cur-fid ! blks bread ;
: clear-fid ( -- ) blks $1000 0 fill  save-blks ;
: new-fid ( -- ) alloc-any dup cur-fid ! mark-used clear-fid ;
: shrink ( n--) fid? cells blks + begin dup fsize < over @ 0<>
  and while  dup @ (mark-free) 0 over ! cell+ repeat drop ;
exception end-exception file-too-large
: enlarge ( nblk -- ) fid? cells blks +
  dup fsize > ['] file-too-large and throw >r 0 blks r>
  begin ( prevblk pcur pmax ) 2dup < while >r
  dup @ 0= if over alloc-after dup (mark-used) over ! then
  nip dup @ swap cell+ r> repeat 2drop drop ;                -->
( filesystem -- fsize! fblk )
: nblk! ( nblk -- ) dup enlarge shrink save-bits ;
: #blks ( bytes. -- blks ) $fff. d+ $1000 ud/mod d>s nip ;
: fsize! ( ud -- ) 2dup fsize 2! #blks nblk! save-blks ;
: fbread ( fb buf -- ) fid? >r cells blks + @ r> bread ;
: fbwrite ( fb buf -- ) fid? >r cells blks + @ r> bwrite ;
$4000 constant fblk             create fb -1 ,
create fblk-dirty 0 ,           2variable fpos
: undirty ( -- ) fblk-dirty @ if fb @ fblk fbwrite
  fblk-dirty off then ;
: fb! ( fb -- ) dup fb @ <> if undirty dup fb ! fblk fbread
  else drop then ;
: fb-reset ( -- ) undirty  -1 fb !  0. fpos 2! ;
: open-fid ( fid -- ) fb-reset open-fid ;
: new-fid  ( -- )     fb-reset new-fid ;                     -->

( filesystem -- fread feof? )
: >blk ( pos. -- off blk ) $1000 ud/mod d>s ;
: blk-use ( blk -- sz ) >r fsize 2@ >blk r> <>
  if drop $1000 then ;
: blk-part ( -- bp sz ) fpos 2@ >blk dup >r fb! dup fblk + swap
  r> blk-use swap - ;
: next-fpos ( sz -- fpos. ) 0 fpos 2@ d+ ;
: advance ( off -- ) next-fpos fpos 2! ;
exception end-exception file-overread
: can-read ( sz -- ) next-fpos fsize 2@ ud>
  ['] file-overread and throw ;
: fread ( buf sz -- ) fid? dup can-read begin dup 0<> while >r
  blk-part r@ min ( buf bp n ) >r over r@ cmove  r@ advance
  r@ + r> r> swap - repeat 2drop ;
: feof? ( -- ? ) fid? fpos 2@ fsize 2@ ud>= ;
: fneof?  feof? invert ;                                     -->
( filesystem -- fwrite pread pwrite fshift< )
: ensure ( sz -- ) next-fpos 2dup fsize 2@ ud>
  if fsize! else 2drop then ;
: fwrite ( buf sz -- ) fid? dup ensure begin dup 0<> while >r
  blk-part r@ min ( buf bp n ) >r 2dup r@ cmove  fblk-dirty on
  r@ advance  drop r@ + r> r> swap - repeat 2drop ;
: pread ( pos. buf sz -- ) fpos 2@ 2>r  2swap fpos 2!  fread
  2r> fpos 2! ;
: pwrite ( pos. buf sz -- ) fpos 2@ 2>r  2swap fpos 2!  fwrite
  2r> fpos 2! ;
$5000 constant fsbuf
: bmax ( sz. -- u ) if drop $1000 else $1000 min then ;
: fshift< ( src. dst. sz. -- ) begin 2dup d0<> while 2dup 2>r
  bmax >r  2over fsbuf r@ pread  2dup fsbuf r@ pwrite
  r@ 0 d+ 2swap  r@ 0 d+ 2swap  r> 2r> rot 0 d- repeat
  2drop 2drop 2drop ;                                        -->
( filesystem -- directories )
: format-filesystem ( -- ) format-freebits new-fid ;
  ( assume new-fid chose blk 1 )
20 stack cwds   1 cwds push     : cwd ( -- fid ) cwds peek ;
: dirent-blk  ( -- blk# ) fsbuf @ ;
: dirent-dir? ( -- t|f ) fsbuf 2 + c@  $80 and 0<> ;
: dirent-name ( -- s u ) fsbuf 2 + count  $7f and ;
: next-dirent ( -- ) fsbuf 3 fread  dirent-name fread ;
: write-dirent ( -- ) fsbuf 3 fwrite  dirent-name fwrite ;
: find-dirent ( name len -- t|f ) cwd open-fid
  begin fneof? while
    next-dirent 2dup dirent-name s=
    if 2drop true exit then
  repeat 2drop false ;                                       -->


( filesystem -- fopen fcreate )
exception  str filename:  end-exception fopen-dir
: fopen? ( name len -- t|f ) 2dup filename: 2! find-dirent
  dup if dirent-dir? ['] fopen-dir and throw
         dirent-blk open-fid then ;
exception  var filename:  end-exception no-such-file
: fopen ( name len -- ) 2dup filename: 2!  fopen?
  invert ['] no-such-file and throw ;
: append ( -- ) fsize 2@ fpos 2! ;
: dirent-blk! ( blk# -- ) fsbuf ! ;
: dirent-name! ( name len -- ) fsbuf 2 + c! dirent-name cmove ;
: dirent-dir! ( -- ) fsbuf 2 + dup c@ $80 or swap c! ;
: append-dirent ( -- ) cwd open-fid append write-dirent ;
: fcreate ( name len -- ) 2dup fopen? if 2drop 0. fsize! else
  new-fid cur-fid @ dup >r dirent-blk!  dirent-name!
  append-dirent r> open-fid then ;                           -->
( filesystem -- mkdir chdir ls )
exception  var filename:  end-exception mkdir-file
: mkdir ( name len -- ) 2dup find-dirent if
  filename: 2! dirent-dir? invert ['] mkdir-file and throw else
  new-fid cur-fid @ dirent-blk!  dirent-name!  dirent-dir!
  append-dirent then ;
: name. ( -- ) dirent-name type cr ;
: dirent. ( -- ) dirent-dir? if lblue then name. noclr ;
: ls ( -- ) cr cwd open-fid begin fneof? while
  next-dirent dirent. repeat ;
: .. ( -- ) cwds stk.depth 1 <> if cwds pop drop then ;
exception  var filename:  end-exception no-such-dir
: chdir ( name len -- ) 2dup filename: 2! find-dirent
  invert ['] no-such-dir and throw
  dirent-dir? invert ['] no-such-dir and throw
  dirent-blk cwds push ;                                     -->
( filesystem -- delete )
exception  var filename:  end-exception cannot-rm-directory
: bytes-left ( -- ud ) fid?  fsize 2@ fpos 2@ d- ;
: fbackspace ( sz. -- ) 2>r  fpos 2@  fpos 2@ 2r@ d-
  bytes-left fshift<  fsize 2@  2r> d- fsize! ;
: delete-dirent ( -- ) dirent-name nip 3 + 0 fbackspace ;
: delete-fid ( fid -- ) dup  open-fid  0. fsize!  mark-free ;
: (delete)  delete-dirent  dirent-blk delete-fid ;
: rm ( name len -- ) 2dup filename: 2!  find-dirent
  invert ['] no-such-file and throw
  dirent-dir? ['] cannot-rm-directory and throw  (delete) ;
exception  var filename:  end-exception not-empty
: rmdir ( name len -- ) 2dup filename: 2!  find-dirent
  invert ['] no-such-dir and throw
  dirent-blk open-fid fsize 2@ d0<> ['] not-empty and throw
  filename: 2@ find-dirent (delete) ;                        -->
( filesystem -- readline exec )
: readline ( b u -- b' ) begin dup 0<> fneof? and while
  over 1 fread  over c@ #lf = if drop exit then
  1 /string repeat drop ;
variable src-fid    2variable src-fpos
: ensure-fid ( fid -- ) dup cur-fid @ <> if open-fid
  else drop then ;
: ensure-src ( -- ) src-fid @ ensure-fid  src-fpos 2@ fpos 2! ;
: refill-file ( -- )
  500 ff readline 0 swap c!  500 >in !  fpos 2@ src-fpos 2! ;
: (exec) ( offset. fname. -- ) src-fid @ >r  src-fpos 2@ 2>r
  fopen cur-fid @ src-fid !  src-fpos 2!
  begin ensure-src fneof? while refill-file interpret repeat
  2r> src-fpos 2!  r> src-fid ! ;
: exec ( fname. -- ) 0. 2swap (exec) ;

