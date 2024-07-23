import chunk
import ../io/readers



type
  iTXtChunk* = ref object of Chunk
    keyword*: string
    text*: string

proc readiTXt*(data: seq[uint8], o: var int): iTXtChunk =
  result.new
  result.keyword = data.readStr(17, o)
  doAssert result.keyword == "XML:com.adobe.xmp"
  result.text = data.readStr(data.len - result.keyword.len, o)
