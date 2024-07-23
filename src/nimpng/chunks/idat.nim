import chunk



# https://www.w3.org/TR/png/#11IDAT
type
  IDATChunk* = ref object of Chunk
    data*: seq[uint8]

proc readIDAT*(data: seq[uint8], o: var int): IDATChunk =
  result.new
  result.data = data[o ..< data.len]
