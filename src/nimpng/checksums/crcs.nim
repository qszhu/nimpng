# https://www.w3.org/TR/png/#D-CRCAppendix
proc initCRC32Table(): array[256, uint32] =
  var c: uint32
  for n in 0 ..< 256:
    c = n.uint32
    for k in 0 ..< 8:
      if (c and 1) != 0:
        c = 0xEDB88320'u32 xor (c shr 1)
      else:
        c = c shr 1
    result[n] = c

const CRC32Table = initCRC32Table()

proc crc32*(data: seq[uint8]): uint32 =
  result = 0xFFFFFFFF'u32
  for b in data:
    let i = (result xor b) and 0xFF
    result = (result shr 8) xor CRC32Table[i]
  result = result xor 0xFFFFFFFF'u32
