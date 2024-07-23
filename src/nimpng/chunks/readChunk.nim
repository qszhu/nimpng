import std/[
  streams,
]

import chunk, ihdr, itxt, phys, idat, iend
import ../io/readers
import ../checksums/crcs

export ihdr, itxt, phys, idat, iend



proc readChunk*(s: Stream): Chunk =
  let length = s.readUint32BE
  let data = s.readBytes(4 + length.int)
  let crc = s.readUint32BE
  if data.crc32 != crc:
    raise newException(IOError, "crc checksum error")

  var o = 0
  let chunkType = data.readStr(4, o)
  case chunkType
  of "IHDR":
    result = data.readIHDR(o)
  of "iTXt":
    result = data.readiTXt(o)
  of "pHYs":
    result = data.readpHYs(o)
  of "IDAT":
    result = data.readIDAT(o)
  of "IEND":
    result = data.readIEND(o)
  else:
    raise newException(ValueError, "Unknown chunk type: " & chunkType)

  result.length = length
  result.chunkType = chunkType
