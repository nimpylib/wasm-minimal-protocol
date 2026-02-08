

when defined(cborious):
  import pkg/cborious
  export cborious
  type CborError* = CborInvalidHeaderError
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
  template Cbor_encode*[T](d: T): untyped =
    bind Cbor, encode
    encode(typeof Cbor, d)
  template Cbor_decode*[T](dd; _: typedesc[T]): T =
    bind Cbor, decode
    decode(typeof Cbor, dd, T)



