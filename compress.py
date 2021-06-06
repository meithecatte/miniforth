SPECIAL_BYTE = b'\xff'
SENTINEL = SPECIAL_BYTE + b'\xef\xbe\xad\xde'

with open('raw.bin', 'rb') as f:
    data = f.read()

output_offset = data.index(b'\xcc' * 20)
chunks = data[output_offset:].lstrip(b'\xcc').split(SENTINEL)

assert SPECIAL_BYTE not in chunks[0]
compressed = bytearray(chunks[0])

for chunk in chunks[1:]:
    assert SPECIAL_BYTE not in chunk
    compressed.extend(SPECIAL_BYTE)
    compressed.extend(chunk)

# Make sure that exactly the right amount of space is allocated
# for the compressed data.
assert b'\xcc' * len(compressed) in data
assert b'\xcc' * (len(compressed) + 1) not in data

output = data[:output_offset] + compressed

print(len(output), 'bytes used')
output += b'\x00' * (510 - len(output))
output += b'\x55\xaa'

with open('boot.bin', 'wb') as f:
    f.write(output)

output += b'\x00' * 512
output += open('test.fth', 'rb').read().replace(b'\n', b' ')
output += b' ' * (2048 - len(output))

with open('test.img', 'wb') as f:
    f.write(output)
