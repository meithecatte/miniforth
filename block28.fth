( stack variables cont. )
: 2,  swap , , ;
: stack ( max-depth ) cells create  here stk-header +
  ( sz buf ) dup , dup , over + ,  latest @ header-name 2,
  allot ;











