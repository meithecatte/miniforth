with open('raw.bin', 'rb') as f:
    data = f.read()
SENTINEL = b'\x90\xef\xbe\xad\xde'
chunks = data.split(SENTINEL)

compressed = bytearray()

for chunk in chunks[1:]:
    assert b'\x90' not in chunk
    compressed.extend(b'\x90')
    compressed.extend(chunk)

assert b'\xcc' * (len(compressed) + 1) not in chunks[0]
output = bytearray(chunks[0])
offset = output.index(b'\xcc' * len(compressed))
output[offset:offset+len(compressed)] = compressed

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
