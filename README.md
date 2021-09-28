# miniforth

`miniforth` is a real mode [FORTH] that fits in an MBR boot sector.
The following standard words are available:

```
+ - ! @ c! c@ dup drop swap emit u. >r r> [ ] : ; load
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

The main goal of the project is bootstrapping a full system on top of Miniforth
as a seed. I describe this in more details [on my blog][blog].

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

 - `>IN` is a word at `0xa02`. It stores the pointer to the first unparsed character
   of the null-terminated input buffer.
 - The stack on boot is `LATEST STATE BASE HERE #DISK` (with `#DISK` on top).
 - `STATE` has a non-standard format - it is a byte, where `0` means compiling,
   and `1` means interpreting.
 - `#DISK` is not a variable, but the saved disk number of the boot media

## Trying it out

When Miniforth boots, no prompt will be shown on the screen. However, if what
you're typing is being shown on the screen, it is working. You can:

 - do some arithmetic: `1 2 + u.`
 - load the code I've developed on top of Miniforth: `1 load`
   - browse that code: `7 21 index`, `7 1000 read-block`, `1000 list`

## Building a disk image

If you have Nix installed, get the build dependencies with `nix-shell`.
Otherwise, you will need `yasm`, `python3`, and optionally, `tup`
(Tup is used instead of Make for Tup's automatic dependency management,
which would be a pain for `mkdisk.py`).

Run

```
tup
```

A non-incremental build can be done without `tup` with the following commands:

```
yasm -f bin boot.s -o raw.bin -l boot.lst
python3 compress.py
python3 mkdisk.py
```

This will create the following artifacts:

- `boot.bin` - the built bootsector.
- `disk.img` - a disk image with the contents of `block*.fth` installed into
  the blocks.
- `boot.lst` - a listing with the raw bytes of each instruction.
   Note that the `dd 0xdeadbeef` are removed by `compress.py`.

The build will print the number of used bytes, as well as the number of block files found.
You can run the resulting disk image in QEMU with `./run.sh`, or pass `./run.sh boot.bin`
if you do not want to include the blocks in your disk. QEMU will run in curses mode, exit
with <kbd>Alt</kbd> + <kbd>2</kbd>, <kbd>q</kbd>, <kbd>Enter</kbd>.

## Getting started

## Hardware considerations

Running Miniforth on real hardware is certainly possible. In fact, I hardly use
emulation for it these days. Anything not unreasonably old should work. However,
most implementations of UEFI have a bug/misfeature where they try to parse the
partition table of an MBR before booting from it. As Miniforth does not include
a partition table in the bootsector (as there is simply no space for it), this
prevents booting on most UEFI computers.

To remedy this, this repository includes a small chainloader to fix it —
`uefix.s`. While running `tup` compiles it, you can also do that manually with

```bash
yasm -f bin uefix.s -o uefix.bin
```

Then, install `uefix.bin` in sector 0, and `boot.bin` in sector 1.

## Free bytes

At this moment, not counting the `55 AA` signature at the end, **504** bytes are used,
leaving 6 byte for any potential improvements.

*Thanks to Ilya Kurdyukov for saving **24** bytes!* These savings have been promptly
reinvested.

If a feature is strongly desirable, potential tradeoffs include:

 - 1 byte: Use a `SPECIAL_BYTE` for compression such that it can be turned into
   `0xad` with `inc [di-1]` or another instruction of the same size. This has
   the disadvantage that avoiding occurances of `SPECIAL_BYTE` becomes harder,
   and the solution of simply changing the special byte no longer works.
 - ?? bytes: Don't expose the `BASE` variable, hardcode hexadecimal — as it
   turns out, it is not that useful. The current block files define a new
   interpreter with its own number conversion routine without touching the
   `BASE`.
 - 7 bytes: Remove the `-` word (with the expectation that the user will assemble their
   own primitives later anyway).
 - 6 bytes: Remove the `+` word (with the expectation that the user will define `: negate 0 swap - ; : + negate - ;`
   - Note that bootstrapping with neither `+` nor `-` would be, to put it mildly, quite hard.
 - 12 bytes: Remove the `emit` word.
 - 9 bytes: Don't push the addresses of variables kept by self-modifying code. This
   essentially changes the API with each edit (NOTE: it's 9 bytes because this makes it
   beneficial to keep `>IN` in the literal field of an instruction).
 - ?? bytes: Instead of storing the names of the primitives, let the user pick their own
   names on boot. This would take very little new code — the decompressor would simply have
   to borrow some code from `:`. However, reboots would become somewhat bothersome.

[FORTH]: https://en.wikipedia.org/wiki/Forth_(programming_language)
[blog]: https://niedzejkob.p4.team/bootstrap/
