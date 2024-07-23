import std/[
  strformat,
]

import chunk
import ../io/readers



# https://www.w3.org/TR/png/#11IHDR
type
  ColorType {.pure.} = enum
    GREYSCALE = 0
    TRUECOLOUR = 2
    INDEXED_COLOUR = 3
    GREYSCALE_WITH_ALPHA = 4
    TRUECOLOUR_WITH_ALPHA = 6

proc readColorType(b: uint8): ColorType =
  case b
  of ColorType.GREYSCALE.uint8: ColorType.GREYSCALE
  of ColorType.TRUECOLOUR.uint8: ColorType.TRUECOLOUR
  of ColorType.INDEXED_COLOUR.uint8: ColorType.INDEXED_COLOUR
  of ColorType.GREYSCALE_WITH_ALPHA.uint8: ColorType.GREYSCALE_WITH_ALPHA
  of ColorType.TRUECOLOUR_WITH_ALPHA.uint8: ColorType.TRUECOLOUR_WITH_ALPHA
  else:
    raise newException(ValueError, "Unknown color type: " & $b)

type
  Interlace {.pure.} = enum
    NO_INTERLACE = 0
    ADAM7_INTERLACE = 1

proc readInterlace(b: uint8): Interlace =
  case b
  of Interlace.NO_INTERLACE.uint8: Interlace.NO_INTERLACE
  of Interlace.ADAM7_INTERLACE.uint8: Interlace.ADAM7_INTERLACE
  else:
    raise newException(ValueError, "Unknown interlace: " & $b)

type
  IHDRChunk* = ref object of Chunk
    width*, height*: uint32
    bitDepth*: uint8
    colorType*: ColorType
    compression*: uint8
    filter*: uint8
    interlace*: Interlace

proc `$`*(self: IHDRChunk): string {.inline.} =
  &"[length: {self.length} chunkType: {self.chunkType} width: {self.width} height: {self.height} bitDepth: {self.bitDepth} colorType: {self.colorType} compression: {self.compression} filter: {self.filter} interlace: {self.interlace}]"

proc readIHDR*(data: seq[uint8], o: var int): IHDRChunk =
  result.new
  result.width = data.readUint32BE(o)
  result.height = data.readUint32BE(o)
  result.bitDepth = data.readUint8(o)
  result.colorType = data.readUint8(o).readColorType

  result.compression = data.readUint8(o)
  doAssert result.compression == 0

  result.filter = data.readUint8(o)
  doAssert result.filter == 0

  result.interlace = data.readUint8(o).readInterlace
