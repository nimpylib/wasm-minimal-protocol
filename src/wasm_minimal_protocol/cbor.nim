

when defined(cborious):
  import pkg/cborious
  export cborious
  type CborError* = CborInvalidHeaderError
  # def is CborObjToArray instead of CborObjToMap
  const flags = {CborObjToMap, CborCheckHoleyEnums}
  template Cbor_encode*[T](d: T): untyped =
    bind toCbor, flags
    toCbor(d, flags)
  template Cbor_decode*[T](dd; _: typedesc[T]): T =
    bind fromCbor, flags
    fromCbor(dd, T, flags)
else:
  import pkg/cbor_serialization
  export cbor_serialization
  template Cbor_encode*[T](d: T): untyped =
    bind Cbor, encode
    encode(typeof Cbor, d)
  template Cbor_decode*[T](dd; _: typedesc[T]): T =
    bind Cbor, decode
    decode(typeof Cbor, dd, T)



