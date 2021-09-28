from itertools import count
import sys

with open('uefix.bin', 'rb') as f:
    output = bytearray(f.read())

with open('boot.bin', 'rb') as f:
    output += bytearray(f.read())

for i in count(1):
    try:
        with open('block%d.fth' % i, 'rb') as f:
            block = f.read()
    except FileNotFoundError:
        break

    lines = block.rstrip(b'\n').split(b'\n')
    if len(lines) <= 16 and all(len(line) <= 64 for line in lines):
        block = b''.join(line.ljust(64) for line in lines)
    else:
        block = block.strip().replace(b'\n', b' ')
    if len(block) > 1024:
        print('Block', i, 'is', len(block), 'bytes')
        sys.exit(1)
    block += b' ' * (1024 - len(block))

    output += block

print('Found', i - 1, 'block files')

with open('miniforth.img', 'wb') as f:
    f.write(output)
