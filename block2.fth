: compile r> dup cell+ >r @ , ;
: immediate latest @ cell+ dup >r c@ 80 + r> c! ;
: br> here 0 , ;
: >br here swap ! ;
: br< here ;
: <br , ;
: if compile (0branch) br> ; immediate
: then >br ; immediate
: else >r compile (branch) br> r> >br ; immediate
: begin br< ; immediate
: again compile (branch) <br ; immediate
: until compile (0branch) <br ; immediate
: while compile (0branch) br> swap ; immediate
: repeat compile (branch) <br >br ; immediate
: foo if 59 emit else 4E emit then ;
