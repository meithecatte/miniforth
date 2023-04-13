from itertools import count
from filesystem import FS, make_partition
import sys

FILE_MAP = [
    (0x01, 'blocks/bootstrap.fth'),
    (0x2f, 'blocks/grep.fth'),
    (0x30, 'blocks/editor.fth'),
    (0x50, 'blocks/filesystem.fth'),
    (0x5f, 'blocks/install.fth'),
    (0x60, 'blocks/feddy.fth'),
]

# Most blocks (which we'll call *formatted*) are stored in the repository
# as 16 lines of length 64 or less, and we can preserve that formatting within
# the disk.

# However, early blocks were written as one long line, and then split
# at each definition within the repository. This kind of formatting won't fit within
# the 16 line split, so we don't preserve it.

def is_formatted(lines):
    return len(lines) <= 16 and all(len(line) <= 64 for line in lines)

def format_block(bnum, block):
    lines = block.strip(b'\n').split(b'\n')
    if is_formatted(lines):
        block = b''.join(line.ljust(64) for line in lines)
    else:
        block = block.strip().replace(b'\n', b' ')
    if len(block) > 1024:
        print('Block', hex(bnum), 'is too large - ', len(block), 'bytes')
        print(block[:64])
        sys.exit(1)
    block += b' ' * (1024 - len(block))
    return block

def read_block(f):
    block = b''
    for line in f:
        block += line
        if line.strip().endswith(b'-->'):
            break
    return block

def blocks_at(begin, fname):
    with open(fname, 'rb') as f:
        for bnum in count(begin):
            block = read_block(f)
            if not block:
                break
            assert bnum not in blocks
            blocks[bnum] = format_block(bnum, block)

if __name__ == "__main__":
    with open('build/uefix.bin', 'rb') as f:
        uefix = f.read()

    with open('build/boot.bin', 'rb') as f:
        boot = f.read()

    blocks = {}
    if boot[0x1be:0x1fe] == bytes(64):
        blocks[0] = boot + bytes(512)
    else:
        print('Using the uefix chainloader to avoid overwriting code with the partition table')
        blocks[0] = uefix + boot

    for bnum, fname in FILE_MAP:
        blocks_at(bnum, fname)

    num_blocks = max(blocks.keys()) + 1

    output = bytearray(1024 * num_blocks)
    for bnum, block in blocks.items():
        offset = 1024 * bnum
        output[offset:offset+1024] = block

    with open('miniforth.img', 'w+b') as f:
        f.write(output)
        start = 2048
        count = 2048
        f.truncate(512 * (start + count))
        make_partition(f, start, count)
        FS(f).pack('files')
