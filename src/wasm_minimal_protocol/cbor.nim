

when defined(cborious):
  import pkg/cborious
  export cborious
  type CborError* = CborInvalidHeaderError
  template writeValue*(s: Stream, val: auto) = cborPack(s, val)
  template readValue*(s: Stream, val: var auto) = cborUnpack(s, val)
  template defineCborPair*(T; writeImpl, readImpl){.dirty.} =
    proc cborPack*(s: Stream; val: T) = writeImpl
    proc cborUnpack*(s: Stream; val: var T) = readImpl
  # def is {CborObjToArray, CborCheckHoleyEnums} instead of CborObjToMap
  const flags = {CborObjToMap, CborEnumAsString, CborCheckHoleyEnums}
  template Cbor_encode*[T](d: T): untyped =
    bind toCbor, flags
    toCbor(d, flags)
  template Cbor_decode*[T](dd; _: typedesc[T]): T =
    bind fromCbor, flags
    fromCbor(dd, T, flags)
else:
  import pkg/cbor_serialization
  import pkg/cbor_serialization/std/[sets as cbor_sets, tables as cbor_tables]
  export cbor_serialization, cbor_sets, cbor_tables
  template defineCborPair*(T; writeImpl, readImpl){.dirty.} =
    proc writeValue*(s: var CborWriter; val: T) = writeImpl
    proc readValue*(s: var CborReader; val: var T) = readImpl
  template Cbor_encode*[T](d: T): untyped =
    bind Cbor, encode
    encode(typeof Cbor, d)
  template Cbor_decode*[T](dd; _: typedesc[T]): T =
    bind Cbor, decode
    decode(typeof Cbor, dd, T)

defineCborPair(char, writeValue(s, $val)):
  var v: string
  readValue(s, v)
  if v.len != 1:
    raise newException(CborError, "Expected a single-character string for char unpacking")
  val = v[0]


