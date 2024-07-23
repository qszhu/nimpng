type
  Chunk* = ref object of RootObj
    length*: uint32
    chunkType*: string
