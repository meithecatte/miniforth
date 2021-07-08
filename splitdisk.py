# Extract the block contents from a disk image.
# Usage: python3 splitdisk.py <disk image> <block count>
# For example, python3 splitdisk.py disk.img 3 will create
# block1.fth, block2.fth, and block3.fth
# Some newlines are added, heuristically. They will get turned back into
# spaces by mkdisk.py anyway. The position of the newlines of the block
# files in the repository has been adjusted manually.

from difflib import SequenceMatcher
from itertools import zip_longest
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

if __name__ == "__main__":
    _, img, count = sys.argv
    count = int(count)

    with open(img, 'rb') as img_file:
        img_file.read(1024)
        for i in range(1, count + 1):
            #print('Processing block', i)
            filename = 'block%d.fth' % i
            block = img_file.read(1024)
            if b'\x00' in block:
                block = block[:block.index(b'\x00')]
            if i <= 6: # HACK: later blocks are formatted properly already
                old_content = b''
                try:
                    with open(filename, 'rb') as f:
                        old_content = f.read().strip()
                except FileNotFoundError:
                    pass
                block = do_split(block, old_content)
            else:
                block = into_lines(block)
            with open(filename, 'wb') as f:
                f.write(block)
