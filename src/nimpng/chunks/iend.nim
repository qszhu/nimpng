import chunk



# https://www.w3.org/TR/png/#11IEND
type
  IENDChunk* = ref object of Chunk

proc readIEND*(data: seq[uint8], o: var int): IENDChunk =
  result.new
