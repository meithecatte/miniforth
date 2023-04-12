SPECIAL_BYTE = b'\xff'
SENTINEL = SPECIAL_BYTE + b'\xef\xbe\xad\xde'

with open('build/raw.bin', 'rb') as f:
    data = f.read()

output_offset = data.index(b'\xcc' * 20)
chunks = data[output_offset:].lstrip(b'\xcc').split(SENTINEL)

assert SPECIAL_BYTE not in chunks[0]
compressed = bytearray(chunks[0])

savings = 0

for chunk in chunks[1:]:
    if compressed[-2] == 0xeb:
        # we end with a jump already, so we would only need a dictionary link. This saves 1 byte.
        savings += 1
    elif compressed[-1] == 0x5b:
        # we'd jump to pop bx/next, so this saves 2 bytes.
        savings += 2
    else:
        # we emit the compression byte, where we could instead have a jump to NEXT followed by the dictionary link,
        # saving 3 bytes
        savings += 3
    assert SPECIAL_BYTE not in chunk
    compressed.extend(SPECIAL_BYTE)
    compressed.extend(chunk)

# EXIT and LIT don't need the dictionary link
savings -= 4

# at least one copy of pop bx / NEXT would be necessary
savings += 4

# account for the cost of the decompressor
savings -= 27

# Make sure that exactly the right amount of space is allocated
# for the compressed data.
assert b'\xcc' * len(compressed) in data
assert b'\xcc' * (len(compressed) + 1) not in data

output = data[:output_offset] + compressed

print(len(output), 'bytes used')
print('Compression saves', savings, 'bytes')
output += b'\x00' * (510 - len(output))
output += b'\x55\xaa'

with open('build/boot.bin', 'wb') as f:
    f.write(output)
