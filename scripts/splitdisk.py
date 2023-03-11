# Extract the block contents from a disk image.
# Usage: python3 splitdisk.py <disk image>
# Some newlines are added, heuristically. They will get turned back into
# spaces by mkdisk.py anyway. The position of the newlines of the block
# files in the repository has been adjusted manually, and this script attempts
# to preserve this formatting as best as it can in the face of modifications.

from itertools import count
from mkdisk import FILE_MAP
from filesystem import FS
import sys

def into_lines(block):
    output = b''
    for i in range(0, len(block), 64):
        line = block[i:i+64].rstrip(b' ')
        output += line + b'\n'
    return output

def blocks_as_file(start, fname, stop=None):
    img_file.seek(start * 1024)
    content = b''

    if stop is None:
        blocks = count(start)
    else:
        blocks = range(start, stop)

    for i in blocks:
        block = img_file.read(1024)
        if b'\x00' in block:
            block = block[:block.index(b'\x00')]
        if not block.strip():
            break
        block = into_lines(block)
        content += block

    with open(fname, 'wb') as f:
        f.write(content)

if __name__ == "__main__":
    _, img = sys.argv

    with open(img, 'rb') as img_file:
        for bnum, fname in FILE_MAP:
            try:
                stop = min(x for x, _ in FILE_MAP if x > bnum)
            except ValueError:
                stop = None
            blocks_as_file(bnum, fname, stop)
        FS(img_file).extract_to('files')
