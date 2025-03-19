# miniforth

`miniforth` is a real mode [FORTH] that fits in an MBR boot sector.
The following standard words are available:

```
- ! @ c! c@ dup swap u. >r r> : ; load
```

Additionally, there are two non-standard words.
 - `|` switches between interpreting and compilation, performing the roles of
   both `[` and `]`.
 - `s: ( buf -- buf+len )` will copy the rest of the current input buffer to
   `buf`, and terminate it with a null byte. The address of said null byte will
   be pushed onto the stack. This is designed for saving the code being ran to
   later put it in a disk block, when no block editor is available yet.

The dictionary is case-sensitive. If a word is not found, it is converted into a number
with no error checking. For example, `g` results in the decimal 16, extending
the `0123456789abcdef` of hexadecimal. On boot, the number base is set to hexadecimal.

Backspace works, but not how you're used to — the erased input will be still visible on
screen until you write something else.

*Various aspects of this project's internals are described in detail [on my blog][blog].*

## Trying it out

You can either build a disk image yourself (see below), or download one from
[the releases page].

When Miniforth boots, no prompt will be shown on the screen. However, if what
you're typing is being shown on the screen, it is working. You can:

 - do some arithmetic:
   ```
   7 5 - u.
   : negate  0 swap - ;
   : +  negate - ;
   69 42 + u.
   ```
 - load additional functionality from disk: `1 load`
   (see [*Onwards from miniforth*](#onwards-from-miniforth) below).

## Building a disk image

You will need `yasm` and `python3`, which you can obtain with `nix-shell` or
your package manager of choice. Then run `./build.sh`.

This will create the following artifacts:

- `build/boot.bin` - the built bootsector.
- `build/uefix.bin` - the chainloader (see below).
- `miniforth.img` - a disk image with the contents of `block*.fth` installed into
  the blocks.
- `build/boot.lst` - a listing with the raw bytes of each instruction.
   Note that the `dd 0xdeadbeef` are removed by `scripts/compress.py`.

The build will print the number of used bytes, as well as the number of block files found.
You can run the resulting disk image in QEMU with `./run.sh`, or pass `./run.sh build/boot.bin`
if you do not want to include the code from `*.fth` in your disk. QEMU will run in curses
mode, exit with <kbd>Alt</kbd> + <kbd>2</kbd>, <kbd>q</kbd>, <kbd>Enter</kbd>.

## Blocks

`load ( blk -- )` loads a 1K block of FORTH source code from disk and executes it.
All other block operations are deferred to user code. Thus, after appropriate setup,
one can get an arbitrarily feature-rich system by simply typing `1 load` —
see [*Onwards from miniforth*](#onwards-from-miniforth) below.

Each pair of sectors on disk forms a single block. Block number 0 is partially used
by the MBR, and is thus reserved.

## System variables

Due to space constraints, variables such as `STATE` or `BASE` couldn't be exposed by creating
separate words. Depending on the variable, the address is either hardcoded or pushed onto
the stack on boot:

 - `>IN` is a word at `0x7d00`. It stores the pointer to the first unparsed character
   of the null-terminated input buffer.
 - The stack on boot is `LATEST STATE BASE HERE #DISK` (with `#DISK` on top).
 - `STATE` has a non-standard format - it is a byte, where `0` means compiling,
   and `1` means interpreting.
 - `#DISK` is not a variable, but the saved disk number of the boot media

## `-DAUTOLOAD`

For some usecases, it might be desirable for the bootsector to load the first
block of Forth code automatically. You can achieve this by building `boot.bin`
with `-DAUTOLOAD`. Unfortunately, this requires 7 more bytes of code, making
miniforth go over the threshold of 446 bytes, which makes it no longer possible
to put an MBR partition table in the boot sector.

The partition table is required for:
 - the filesystem code in `blocks/filesystem.fth`
 - booting in the BIOS compatibility mode of most UEFI implementations, due to
   a common bug/misfeature.

To work around this, `scripts/mkdisk.py` will use the small chainloader in
`uefix.s` when it detects that miniforth is larger than 446 bytes.
Instead of the default disk layout, which looks like this:

```
LBA 0   - boot.bin
LBA 1   - unused
LBA 2-3 - Forth block 1
...       ...
```

...the disk image will looks as follows:

```
LBA 0   - uefix.bin
LBA 1   - boot.bin
LBA 2-3 - Forth block 1
...       ...
```

## Onwards from miniforth

The main goal of the project is bootstrapping a full system on top of Miniforth
as a seed. Thus the repository also contains various Forth code that may run on
top of Miniforth and extend its capabilities.

 - In `blocks/bootstrap.fth` (`1 load`):
   - A simple assembler is implemented, and then used to implement additional
     primitives, which wouldn't fit in Miniforth itself. This includes control
     flow words like `IF`/`THEN` and `BEGIN`/`UNTIL`, as well as calls to the BIOS
     disk interrupt to allow manipulating the code on disk.

     For the syntax of the assembler, see [*No branches? No problem — a Forth
     assembler*][branch-blog].

   - Exception handling is implemented, with semantics a little different from
     standard Forth. See [*Contextful exceptions with Forth
     metaprogramming*][exception-blog].
   - A separate, more featureful outer interpreter overrides the one built into
     Miniforth, to correct the ugly backspace behavior and handle things
     such as uncaught exceptions and vocabularies.
 - In `blocks/grep.fth` (`2f load`), a way of searching for occurences of a
   particular string in the code stored in the blocks is provided:
   - `10 20 grep create` searches blocks `$10` through `$20` inclusive for
     occurences of `create`
   - If your search term includes spaces, use `grep"` — the syntax is similar
     to `s"` string literals: `10 20 grep" : >number"`
 - In `editor.fth` (`30 load`), a vi-like block editor is implemented. It can be started
   with e.g. `10 edit` to edit block 10.
   - Non-standard keybindings:
     - <kbd>Q</kbd> to quit back to the Forth REPL.
     - <kbd>[</kbd> to look at the previous block.
     - <kbd>]</kbd> to look at the next block.
   - After first use, you can use the shorthand `ed` to reopen the last-edited block.
   - Use `run` to execute the last-edited block. This sets a flag to prevent
     a chain of `-->` from loading all the subsequent blocks.
   - Changes are saved to disk whenever you use `run` or open a different block with `edit`
     or the <kbd>[</kbd>/<kbd>]</kbd> keybinds. You can also trigger this
     manually with `save`.
 - In `filesystem.fth` (`50 load`), there's support for a simple filesystem,
   which is currently hardcoded to be in the first partition listed in the MBR.
   Some limits are lower than you might expect, but for the purposes I'm
   interested in, they shouldn't become a problem:
   - Partition size: up to 128 MiB
   - File size: 8184 KiB

   One file can be open at a time. Directories are supported, but there isn't any
   path parsing. For user-level file manipulation:
   - `ls ( -- )` will print the list of files in the current directory.
   - `chdir ( name len -- )` will enter a subdirectory.
   - `.. ( -- )` will go back to the parent directory.
   - `mkdir ( name len -- )` will create a directory.
   - `exec ( name len -- )` will execute the contents of a file as Forth.
   - `rm ( name len -- )` will delete a file.
   - `rmdir ( name len -- )` will delete an empty directory. Recursive delete
     is not implemented yet.
   For writing programs involving files:
   - `fopen ( name len -- )` will open an existing file, or throw an exception
     if it doesn't exist.
   - `fopen? ( name len -- t|f )` will instead return a boolean indicating
     whether the file could be found.
   - `fcreate ( name len -- )` will create a new file, or if it already exists,
     truncate it to 0 bytes. The new file is opened.
   - `fread ( buf len -- )` will read data starting at the current position

All this code was originally developed within Miniforth itself, which meant it was
stored within a disk image — a format that's not very friendly to tooling like
Git or GitHub's web interface. This disparity is handled by two Python scripts:

 - `scripts/mkdisk.py` takes the files and merges them into a bootable disk image;
 - `scripts/splitdisk.py` extracts the code from a disk image's blocks and splits
   it into files.

## Free bytes

At this moment, not counting the `55 AA` signature at the end, **444** bytes are used,
leaving 2 bytes for any potential improvements.

Byte saving leaderboard:
 - Ilya Kurdyukov saved 24 bytes. Thanks!
 - Peter Ferrie saved 5 bytes. Thanks!
 - [An article][daa] by Sean Conner allowed me to save 2 bytes. Thanks!

If a feature is strongly desirable, potential tradeoffs include:

 - 7 bytes: Don't push the addresses of variables kept by self-modifying code. This
   essentially changes the API with each edit (NOTE: it's 7 bytes because this makes it
   beneficial to keep `>IN` in the literal field of an instruction).
 - ?? bytes: Instead of storing the names of the primitives, let the user pick their own
   names on boot. This would take very little new code — the decompressor would simply have
   to borrow some code from `:`. However, reboots would become somewhat bothersome.
 - ?? bytes: Instead of providing `;` in the kernel, give a dictionary entry to `EXIT` and
   terminate definitions with `\` |` until `immediate` and `;` can be defined.

[FORTH]: https://en.wikipedia.org/wiki/Forth_(programming_language)
[blog]: https://compilercrim.es/bootstrap/
[branch-blog]: https://compilercrim.es/bootstrap/branches/
[exception-blog]: https://compilercrim.es/bootstrap/exception-context/
[the releases page]: https://github.com/meithecatte/miniforth/releases/
[daa]: https://boston.conman.org/2023/02/24.1
