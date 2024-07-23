import std/[
  strformat,
]

import chunk
import ../io/readers



# https://www.w3.org/TR/png/#11pHYs
type
  pHYsChunk* = ref object of Chunk
    pixelsPerUnitX*: uint32
    pixelsPerUnitY*: uint32
    unitSpecifier*: uint8

proc `$`*(self: pHYsChunk): string {.inline.} =
  &"[pixelsPerUnitX: {self.pixelsPerUnitX} pixelsPerUnitY: {self.pixelsPerUnitY} unitSpecifier: {self.unitSpecifier}]"

proc readpHYs*(data: seq[uint8], o: var int): pHYsChunk =
  result.new
  result.pixelsPerUnitX = data.readUint32BE(o)
  result.pixelsPerUnitY = data.readUint32BE(o)
  result.unitSpecifier = data.readUint8(o)
