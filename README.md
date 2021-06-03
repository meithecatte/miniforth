# miniforth

`miniforth` is a real mode [FORTH] that fits in an MBR boot sector.
The following words are available:

```
+ - ! @ c! c@ dup drop swap emit u. >r r> [ ] : ; load
```

The dictionary is case-sensitive. If a word is not found, it is converted into a number
with no error checking. For example, `g` results in the decimal 16, extending
the `0123456789abcdef` of hexadecimal. On boot, the number base is set to hexadecimal.

Backspace works, but doesn't erase the input with spaces, so until you write something else,
the screen will look a bit weird.

## Blocks

`load ( blk -- )` loads a 1K block of FORTH source code from disk and executes it.
All other block operations are deferred to user code. Thus, after appropriate setup,
one can get an arbitrarily feature-rich system by simply typing `1 load`.

Each pair of sectors on disk forms a single block. Block number 0 is partially used
by the MBR, and is thus reserved.

## System variables

Due to space constraints, variables such as `STATE` or `BASE` couldn't be exposed by creating
separate words. Depending on the variable, the address is either hardcoded or pushed onto
the stack on boot:

 - `LATEST` is a word at `0xb02`. It stores the head of the dictionary linked list.
 - `>IN` is a word at `0xb04`. It stores the pointer to the first unparsed character
   of the null-terminated input buffer.
 - The stack on boot is `STATE BASE HERE` (with `HERE` on top).
 - `STATE` has a non-standard format - it is a byte, where `0x80` means compiling,
   and `0xff` means interpreting.

## Building

Run `make`. You will need yasm and python3. This will create the following artifacts:

- `boot.bin` - the built bootsector. You can run it in QEMU with `make run`.
- `test.img` - a disk image with the contents of `test.fth` added to block 1.
  You can run it in QEMU with `make test`.
- `boot.lst` - a listing with the raw bytes of each instruction.
   Note that the `dd 0xdeadbeef` are removed during post-processing.

The build will print the number of used bytes.

## Free bytes

At this moment, not counting the `55 AA` signature at the end, **503** bytes are used,
leaving 7 bytes for any potential improvements. If a feature is strongly desirable,
potential tradeoffs include:

 - 2 bytes: Removing the `cli/sti` around initialization code. This creates a 2-instruction
   wide race condition window during boot, during which an interrupt could crash the system
   depending on where the BIOS decided to put the stack. I did not observe this happening
   in practice, though.
 - 7 bytes: Remove the `-` word.
 - 12 bytes: Remove the `emit` word.

So far, nobody has found any bytes to be saved in my code, [so it must be optimal][cunningham] ;)

[FORTH]: https://en.wikipedia.org/wiki/Forth_(programming_language)
[cunningham]: https://meta.wikimedia.org/wiki/Cunningham%27s_Law
