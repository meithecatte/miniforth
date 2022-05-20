( editor: keymaps )
: callot here over allot swap 0 fill ;
value keypress
: unbound status ." Unbound key " keypress dup u. emit ;
: keymap create ['] unbound , $100 cells callot does>
  keypress lobyte 1+ cells over + @ ( map handler )
  dup if nip else drop @ then execute ;
: >> latest @ >xt ;
: bind ( xt c -- ) 1+ cells ' >body + ! ;
defer current-keymap            keymap normal
: normal-mode  ['] modeline-normal is modeline
  ['] normal is current-keymap ;
: handle-key  key to keypress  ['] current-keymap catch
  dup if status red execute else drop then ;
: edit-loop normal-mode need-redraw on  begin render
  need-redraw on  handle-key  again ;                        -->
