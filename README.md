# miniforth

`miniforth` is a real mode [FORTH] that fits in an MBR boot sector.
The following standard words are available:

```
+ ! @ c! c@ dup drop swap emit u. >r r> [ ] : ; load
```

Additionally, there is one non-standard word. `s: ( buf -- buf+len )` will copy the
rest of the current input buffer to `buf`, and terminate it with a null byte. The address
of said null byte will be pushed onto the stack. This is designed for saving the code being
ran to later put it in a disk block, when no block editor is available yet.

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

 - `>IN` is a word at `0xb04`. It stores the pointer to the first unparsed character
   of the null-terminated input buffer.
 - The stack on boot is `LATEST STATE BASE HERE #DISK` (with `#DISK` on top).
 - `STATE` has a non-standard format - it is a byte, where `0x75` means compiling,
   and `0xeb` means interpreting.
 - `#DISK` is not a variable, but the saved disk number of the boot media

## Building

Run `make`. You will need yasm and python3. This will create the following artifacts:

- `boot.bin` - the built bootsector. You can run it in QEMU with `make run`.
- `test.img` - a disk image with the contents of `test.fth` added to block 1.
  You can run it in QEMU with `make test`.
- `boot.lst` - a listing with the raw bytes of each instruction.
   Note that the `dd 0xdeadbeef` are removed during post-processing.

The build will print the number of used bytes.

## Free bytes

At this moment, not counting the `55 AA` signature at the end, **501** bytes are used,
leaving 9 byte for any potential improvements.

*Thanks to Ilya Kurdyukov for saving **20** bytes!*

If a feature is strongly desirable, potential tradeoffs include:

 - 12 bytes: Remove the `emit` word.
 - 8 bytes: Don't push the addresses of variables kept by self-modifying code. This
   essentially changes the API with each edit.

[FORTH]: https://en.wikipedia.org/wiki/Forth_(programming_language)
