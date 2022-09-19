# Extract the block contents from a disk image.
# Usage: python3 splitdisk.py <disk image>
# Some newlines are added, heuristically. They will get turned back into
# spaces by mkdisk.py anyway. The position of the newlines of the block
# files in the repository has been adjusted manually, and this script attempts
# to preserve this formatting as best as it can in the face of modifications.

from difflib import SequenceMatcher
from itertools import zip_longest, count
from mkdisk import read_block, FILE_MAP
import re
import sys

def seps(s):
    return re.findall(rb'\s+', s)

def into_lines(block):
    output = b''
    for i in range(0, len(block), 64):
        line = block[i:i+64].rstrip(b' ')
        output += line + b'\n'
    return output

def do_split(content, old):
    old_words = old.split()
    new_words = content.split()
    differ = SequenceMatcher(None, old_words, new_words)
    old_seps = seps(old)
    output = b''
    for tag, l, r, L, R in differ.get_opcodes():
        if tag == 'equal':
            for word, sep in zip_longest(old_words[l:r], old_seps[l:r]):
                output += word + (sep or b' ')
        else:
            for word in new_words[L:R]:
                split = word.startswith(b':') or word in [b'-->', b'variable']
                if split and output.endswith(b' '):
                    output = output[:-1] + b'\n'
                output += word + b' '
    output = output.strip()
    output += b'\n'
    return output

def blocks_as_file(start, fname):
    img_file.seek(start * 1024)
    new_content = b''
    try:
        f = open(fname, 'rb')
    except FileNotFoundError:
        f = None

    for i in count(start):
        block = img_file.read(1024)
        if b'\x00' in block:
            block = block[:block.index(b'\x00')]
        if not block.strip():
            break
        if i <= 6: # HACK: later blocks are formatted properly already
            if f is not None:
                old_content = read_block(f)
            else:
                old_content = b''
            block = do_split(block, old_content)
        else:
            block = into_lines(block)
        new_content += block

    if f is not None:
        f.close()
    with open(fname, 'wb') as f:
        f.write(new_content)

if __name__ == "__main__":
    _, img = sys.argv

    with open(img, 'rb') as img_file:
        for bnum, fname in FILE_MAP:
            blocks_as_file(bnum, fname)
