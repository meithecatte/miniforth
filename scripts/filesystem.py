# Handles our filesystem for mkdisk.py and splitdisk.py (see blocks/filesystem.fth)
import os
import struct

def chs(lba):
    track, sector = divmod(lba, 63)
    cyl, head = divmod(track, 16)
    return cyl, head, sector + 1

def pack_chs(lba):
    c, h, s = chs(lba)
    return bytes([h, ((c >> 8) << 6) | s, c % 256])

def ptable_entry(start, count, ty):
    return struct.pack('<B3sB3sII',
        0, pack_chs(start), ty, pack_chs(start + count - 1), start, count)

def make_partition(img, start, count):
    img.seek(446)
    img.write(ptable_entry(start, count, 0x69))

class FS:
    def __init__(self, img):
        self.img = img
        self.lba0, self.num_sectors = self.read_ptable()
        self.freebits = bytearray(self.read_block(0))

    def format(self):
        self.freebits = bytearray(4096)
        self.freebits[0] |= 1
        for i in range(self.num_sectors // 8, 4096 * 8):
            self.mark_used(i)

    def mark_used(self, blk):
        byte, bit = divmod(blk, 8)
        self.freebits[byte] |= 1 << bit

    def is_unused(self, blk):
        byte, bit = divmod(blk, 8)
        return self.freebits[byte] & (1 << bit) == 0

    def find_unused(self):
        for i, b in enumerate(self.freebits):
            if b == 0xff:
                continue
            for j in range(8):
                if b & (1 << j) == 0:
                    return 8 * i + j
        else:
            raise Exception("out of space")

    def find_unused_continuous(self):
        for i, b in enumerate(self.freebits):
            if b == 0:
                return 8 * i
        return self.find_unused()

    def unmount(self):
        self.write_block(0, self.freebits)

    def read_ptable(self):
        self.img.seek(446)
        tab = self.img.read(16)
        _, start, length = struct.unpack('<QII', tab)
        return start, length

    def read_block(self, n):
        self.img.seek(self.lba0 * 512 + n * 4096)
        return self.img.read(4096)

    def write_block(self, n, data):
        assert len(data) == 4096
        self.img.seek(self.lba0 * 512 + n * 4096)
        self.img.write(data)

    def read_fid(self, fid):
        blocklist = self.read_block(fid)
        fsize, = struct.unpack('<I', blocklist[-4:])
        num_blocks = (fsize + 4095) // 4096
        data = b''
        for i in range(0, 2 * num_blocks, 2):
            bnum, = struct.unpack('<H', blocklist[i:i+2])
            assert bnum > 0
            data += self.read_block(bnum)
        assert len(data) >= fsize
        return data[:fsize]

    def readdir(self, fid):
        data = self.read_fid(fid)
        files = []
        dirs = []
        while data:
            fid, namelen = struct.unpack('<HB', data[:3])
            isdir = namelen & 0x80 != 0
            namelen &= 0x7f
            name = data[3:3+namelen].decode()
            data = data[3+namelen:]
            if isdir:
                dirs.append((fid, name))
            else:
                files.append((fid, name))
        return files, dirs

    def extract_dir(self, fid, path):
        os.makedirs(path, exist_ok=True)
        files, dirs = self.readdir(fid)
        for fid, name in files:
            with open(path + '/' + name, 'wb') as f:
                f.write(self.read_fid(fid))
        for fid, name in dirs:
            self.extract_dir(fid, path + '/' + name)

    def extract_to(self, path):
        self.extract_dir(1, path)

    def create_fid(self, contents, fid=None):
        if fid is None:
            fid = self.find_unused()
        self.mark_used(fid)
        blocks = []
        fsize = len(contents)
        while contents:
            block = contents[:4096]
            contents = contents[4096:]
            if blocks and self.is_unused(blocks[-1] + 1):
                bnum = blocks[-1] + 1
            else:
                bnum = self.find_unused_continuous()
            self.mark_used(bnum)
            block += bytes(4096 - len(block))
            self.write_block(bnum, block)
            blocks.append(bnum)
        blocks += [0] * (4092 // 2 - len(blocks))
        blocklist = b''.join(struct.pack('<H', x) for x in blocks)
        blocklist += struct.pack('<I', fsize)
        self.write_block(fid, blocklist)
        return fid

    def create_dir(self, files, dirs, fid=None):
        data = bytearray()
        for entry_fid, name in dirs:
            name = name.encode()
            data += struct.pack('<HB', entry_fid, 0x80 | len(name))
            data += name
        for entry_fid, name in files:
            name = name.encode()
            data += struct.pack('<HB', entry_fid, len(name))
            data += name
        return self.create_fid(data, fid)

    def pack_dir(self, path, fid=None):
        if fid is not None:
            self.mark_used(fid)
        files = []
        dirs = []
        for entry in os.scandir(path):
            if entry.is_dir():
                entry_fid = self.pack_dir(entry.path)
                dirs.append((entry_fid, entry.name))
            else:
                with open(entry.path, 'rb') as f:
                    data = f.read()
                entry_fid = self.create_fid(data)
                files.append((entry_fid, entry.name))
        return self.create_dir(files, dirs, fid)

    def pack(self, path):
        self.format()
        self.pack_dir(path, 1)
        self.unmount()
