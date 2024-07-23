import pkg/nimzlib

import nimpng/io/readers
import nimpng/chunks/readChunk



const PNG_HEADER: seq[uint8] = @[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

type
  PNGImage* = ref object
    width*, height*, bitDepth*, channels*: int
    data*: seq[uint8]

proc paeth(a, b, c: uint8): int =
  let (a, b, c) = (a.int, b.int, c.int)
  let p = a + b - c
  let pa = (p - a).abs
  let pb = (p - b).abs
  let pc = (p - c).abs
  if pa <= pb and pa <= pc: a
  elif pb <= pc: b
  else: c

# https://www.w3.org/TR/PNG-Filters.html
proc defilter(self: PNGImage, s: Stream) =
  s.setPosition(0)
  self.data = newSeq[uint8](self.width * self.height * self.channels)
  let stride = self.width * self.channels
  let bpp = (self.bitDepth * self.channels + 7) div 8
  for r in 0 ..< self.height:
    let i = r * stride
    let ft = s.readUint8
    let line = s.readBytes(stride)
    for j in 0 ..< stride:
      let x = line[j]
      let a = if j - bpp < 0: 0'u8 else: self.data[i + j - bpp]
      let b = if i == 0: 0'u8 else: self.data[i - stride + j]
      let c = if i == 0 or j - bpp < 0: 0'u8 else: self.data[i - stride + j - bpp]
      case ft
      of 0: # None
        self.data[i + j] = x
      of 1: # Sub
        self.data[i + j] = ((x.int + a.int) mod 256).uint8
      of 2: # Up
        self.data[i + j] = ((x.int + b.int) mod 256).uint8
      of 3: # Average
        self.data[i + j] = ((x.int + ((a.int + b.int) shr 1)) mod 256).uint8
      of 4: # Paeth
        self.data[i + j] = ((x.int + paeth(a, b, c)) mod 256).uint8
      else:
        raise newException(ValueError, "Invalid filter type: " & $ft)

proc open*(fn: string): PNGImage =
  result.new
  var f: File
  if not open(f, fn):
    raise newException(IOError, "Error opening file: " & fn)

  var fs = newFileStream(f)
  try:
    if fs.readBytes(8) != PNG_HEADER:
      raise newException(IOError, "PNG header not found")

    var dataStream = newStringStream()
    while not fs.atEnd:
      let chunk = fs.readChunk
      case chunk.chunkType
      of "IHDR":
        let c = chunk.IHDRChunk
        result.width = c.width.int
        result.height = c.height.int
        result.bitDepth = c.bitDepth.int
        case c.colorType
        of TRUECOLOUR:
          result.channels = 3
        else:
          raise newException(ValueError, "Unsupported color type: " & $c.colorType)
      of "IDAT":
        dataStream.writeData(addr(chunk.IDATChunk.data[0]), chunk.IDATChunk.data.len)
      else:
        discard
        # echo (chunk.chunkType, chunk.length)

    dataStream.setPosition(0)
    result.defilter(inflate(dataStream))

  finally:
    fs.close

proc getRGBA*(self: PNGImage, flipY = true): seq[uint8] =
  if self.channels == 4: return self.data
  doAssert self.channels == 3
  result = newSeq[uint8](self.width * self.height * 4)
  var j = 0
  for i in countup(0, self.data.len - 1, 3):
    result[j] = self.data[i]
    result[j + 1] = self.data[i + 1]
    result[j + 2] = self.data[i + 2]
    result[j + 3] = 0xff
    j += 4
  let stride = self.width * 4
  if flipY:
    for c in 0 ..< stride:
      var r0 = 0
      var r1 = self.height - 1
      while r0 < r1:
        swap(result[r0 * stride + c], result[r1 * stride + c])
        (r0, r1) = (r0 + 1, r1 - 1)

when isMainModule:
  import strformat, strutils

  let png = open("test.png")
  var lines = newSeq[string]()
  lines.add "P3"
  lines.add &"{png.width} {png.height}"
  lines.add "255"
  let data = png.getRGBA
  for i in countup(0, data.len - 1, 4):
    lines.add &"{data[i + 0]} {data[i + 1]} {data[i + 2]}"
  writeFile("out.ppm", lines.join("\n"))
