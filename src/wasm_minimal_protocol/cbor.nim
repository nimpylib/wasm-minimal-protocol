
import pkg/cbor_serialization
export cbor_serialization

template Cbor_encode*[T](d: T): untyped =
  bind Cbor, encode
  encode(typeof Cbor, d)
template Cbor_decode*[T](dd; _: typedesc[T]): T =
  bind Cbor, decode
  decode(typeof Cbor, dd, T)

