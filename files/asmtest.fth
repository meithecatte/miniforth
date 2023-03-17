( assembly tests )
s" test.fth" require Tester
s" asm32.fth" require Assembler
create buf $10 allot
variable bufpos
buf $10 + constant bufend

exception end-exception test-buffer-overflow
: test-db ( c -- )
  bufpos @ bufend < if
    bufpos @ c!
    1 bufpos +!
  else
    ['] test-buffer-overflow
  then ;

Tester
: check-depth0 ( -- ) depth depth0 @ <> if
  cr ." dirty stack" .s cr to-depth0 then ;
previous
: #->
  check-depth0
  buf begin dup bufpos @ < while
    dup c@ swap 1+
  repeat drop
  >-> ;
: t{ t{ buf bufpos ! ;

Assembler
' test-db is db

t{ -81. 32imm8? >-> false }t
t{ -80. 32imm8? >-> true }t
t{ -1.  32imm8? >-> true }t
t{ 0.   32imm8? >-> true }t
t{ 1.   32imm8? >-> true }t
t{ 7F.  32imm8? >-> true }t
t{ 80.  32imm8? >-> false }t
t{ 12345. 32imm8? >-> false }t

32bit off
t{ lodsb #-> AC }t
t{ lodsw #-> AD }t
t{ lodsd #-> 66 AD }t
t{ lgdt [bx] #-> 0F 01 17 }t
t{ lgdt [ecx] #-> 67 0F 01 11 }t
t{ lgdt $2137 [#] #-> 0F 01 16 37 21 }t
t{ push cx #-> 51 }t
t{ push edx #-> 66 52 }t

32bit on
t{ lodsb #-> AC }t
t{ lodsw #-> 66 AD }t
t{ lodsd #-> AD }t
t{ lgdt [bx] #-> 67 0F 01 17 }t
t{ lgdt [ecx] #-> 0F 01 11 }t
t{ lgdt $2137 [#] #-> 0F 01 15 37 21 00 00 }t
t{ push cx #-> 66 51 }t
t{ push edx #-> 52 }t

32bit off
t{ mov cl $69 # #-> B1 69 }t
t{ mov cx $1234 # #-> B9 34 12 }t
t{ mov ecx $12345678. .# #-> 66 B9 78 56 34 12 }t

32bit on
t{ mov cl $69 # #-> B1 69 }t
t{ mov cx $1234 # #-> 66 B9 34 12 }t
t{ mov ecx $12345678. .# #-> B9 78 56 34 12 }t

32bit off
t{ mov byte [si] $69 # #-> C6 04 69 }t
t{ mov byte [bp] $69 # #-> C6 46 00 69 }t
t{ mov byte 4 [bp+#] $69 # #-> C6 46 04 69 }t
t{ mov byte -4 [bp+#] $69 # #-> C6 46 FC 69 }t
t{ mov byte FC [bp+#] $69 # #-> C6 86 FC 00 69 }t
t{ mov byte 4 [si+#] $69 # #-> C6 44 04 69 }t
t{ mov word [si] $1234 # #-> C7 04 34 12 }t
t{ mov byte [eax] $69 # #-> 67 C6 00 69 }t

32bit on
t{ mov byte [esi] $69 # #-> C6 06 69 }t
t{ mov byte [ebp] $69 # #-> C6 45 00 69 }t
t{ mov byte [esp] $69 # #-> C6 04 24 69 }t
t{ mov byte 4 [esi+#] $69 # #-> C6 46 04 69 }t
t{ mov byte 4 [ebp+#] $69 # #-> C6 45 04 69 }t
t{ mov byte 123 [esi+#] $69 # #-> C6 86 23 01 00 00 69 }t
t{ mov word [esi] $2137 # #-> 66 C7 06 37 21 }t
t{ mov dword [esi] $deadbeef. .# #-> C7 06 EF BE AD DE }t
t{ mov byte $abcde. [.#] 10 # #-> C6 05 DE BC 0A 00 10 }t

32bit off
t{ mov al cl #-> 88 C8 }t
t{ mov al [bx] #-> 8A 07 }t
t{ mov ax [bx] #-> 8B 07 }t
t{ mov bp [bp] #-> 8B 6E 00 }t
t{ mov [si] ch #-> 88 2C }t
t{ mov [di] dx #-> 89 15 }t
t{ mov bx $dead [#] #-> 8B 1E AD DE }t
t{ mov bx $7f [#] #-> 8B 1E 7F 00 }t
t{ mov cx dx #-> 89 D1 }t
t{ mov ecx edx #-> 66 89 D1 }t

32bit on
t{ mov al cl #-> 88 C8 }t
t{ mov dl [ebx] #-> 8A 13 }t
t{ mov ax [bx] #-> 66 67 8B 07 }t
t{ mov si [ecx] #-> 66 8B 31 }t
t{ mov esi [ecx] #-> 8B 31 }t
t{ mov 4 [ebp+#] edi #-> 89 7D 04 }t

32bit off
t{ add al $69 # #-> 04 69 }t
t{ add ax $2137 # #-> 05 37 21 }t
t{ add eax $deadbeef. .# #-> 66 05 EF BE AD DE }t
t{ xor al $69 # #-> 34 69 }t
t{ xor ax $2137 # #-> 35 37 21 }t
t{ xor eax $deadbeef. .# #-> 66 35 EF BE AD DE }t

32bit on
t{ add al $69 # #-> 04 69 }t
t{ add ax $2137 # #-> 66 05 37 21 }t
t{ add eax $deadbeef. .# #-> 05 EF BE AD DE }t
t{ xor al $69 # #-> 34 69 }t
t{ xor ax $2137 # #-> 66 35 37 21 }t
t{ xor eax $deadbeef. .# #-> 35 EF BE AD DE }t

32bit off
t{ add bh $69 # #-> 80 C7 69 }t
t{ add cx $2137 # #-> 81 C1 37 21 }t
t{ add cx $69 # #-> 83 C1 69 }t
t{ add cx -1 # #-> 83 C1 FF }t
t{ xor bh $69 # #-> 80 F7 69 }t
t{ xor cx $2137 # #-> 81 F1 37 21 }t
t{ xor cx $69 # #-> 83 F1 69 }t
t{ xor cx $FFFF # #-> 83 F1 FF }t

32bit on
t{ add bh $69 # #-> 80 C7 69 }t
t{ add cx $2137 # #-> 66 81 C1 37 21 }t
t{ add ecx $deadbeef. .# #-> 81 C1 EF BE AD DE }t
t{ xor cl $69 # #-> 80 F1 69 }t
t{ xor cx $2137 # #-> 66 81 F1 37 21 }t
t{ xor ecx $deadbeef. .# #-> 81 F1 EF BE AD DE }t
t{ xor ecx $69 # #-> 83 F1 69 }t
t{ xor ecx -1 # #-> 81 F1 FF FF 00 00 }t
t{ xor ecx -1. .# #-> 83 F1 FF }t

32bit off
t{ xor ax ax #-> 31 C0 }t
t{ sub ax [si] #-> 2B 04 }t
t{ sbb 7 [#] cl #-> 18 0E 07 00 }t

32bit off
t{ ror dword [edx] 7 # #-> 67 66 C1 0A 07 }t
t{ shl cx cl #-> D3 E1 }t
t{ rcl si 1 # #-> D1 D6 }t

32bit on
t{ ror dword [edx] 7 # #-> C1 0A 07 }t
t{ shl cx cl #-> 66 D3 E1 }t
t{ rcl si 1 # #-> 66 D1 D6 }t

32bit off
t{ mov cr2 esi #-> 0F 22 D6 }t
t{ mov edi cr4 #-> 0F 20 E7 }t

32bit on
t{ mov cr2 esi #-> 0F 22 D6 }t
t{ mov edi cr4 #-> 0F 20 E7 }t

32bit off
t{ mov si cs #-> 8C CE }t
t{ mov edi ds #-> 66 8C DF }t
( how-wide is too dumb for these, let's skip it )
( t{ mov [bx] ss #-> 8C 17 }t         )
( t{ mov [ecx] es #-> 67 8C 01 }t     )

32bit on
t{ mov si cs #-> 66 8C CE }t
t{ mov edi ds #-> 8C DF }t
( t{ mov [bx] ss #-> 67 8C 17 }t      )
( t{ mov [ecx] es #-> 8C 01 }t        )

32bit off
t{ in al dx #-> EC }t
t{ in ax dx #-> ED }t
t{ in eax dx #-> 66 ED }t
t{ in al $69 # #-> E4 69 }t
t{ in ax $69 # #-> E5 69 }t
t{ in eax $69 # #-> 66 E5 69 }t

t{ out dx al #-> EE }t
t{ out dx ax #-> EF }t
t{ out dx eax #-> 66 EF }t
t{ out $69 # al #-> E6 69 }t
t{ out $69 # ax #-> E7 69 }t
t{ out $69 # eax #-> 66 E7 69 }t

32bit on
t{ in al dx #-> EC }t
t{ in ax dx #-> 66 ED }t
t{ in eax dx #-> ED }t
t{ in al $69 # #-> E4 69 }t
t{ in ax $69 # #-> 66 E5 69 }t
t{ in eax $69 # #-> E5 69 }t

t{ out dx al #-> EE }t
t{ out dx ax #-> 66 EF }t
t{ out dx eax #-> EF }t
t{ out $69 # al #-> E6 69 }t
t{ out $69 # ax #-> 66 E7 69 }t
t{ out $69 # eax #-> E7 69 }t

32bit off
t{ jmpf $1234 # $5678 # #-> EA 78 56 34 12 }t

32bit on
t{ jmpf $08 # $deadbeef. .# #-> EA EF BE AD DE 08 00 }t

' c, is db
previous
