# Extract the block contents from a disk image.
# Usage: python3 splitdisk.py <disk image> <block count>
# For example, python3 splitdisk.py disk.img 3 will create
# block1.fth, block2.fth, and block3.fth
# Some newlines are added, heuristically. They will get turned back into
# spaces by mkdisk.py anyway. The position of the newlines of the block
# files in the repository has been adjusted manually.

import sys
_, img, count = sys.argv
count = int(count)

with open(img, 'rb') as f:
    data = f.read()

for i in range(1, count + 1):
    block = data[1024*i:1024*(i+1)]
    if b'\x00' in block:
        block = block[:block.index(b'\x00')]
    block = block.replace(b'; ', b';\n')
    with open('block%d.fth' % i, 'wb') as f:
        f.write(block)
