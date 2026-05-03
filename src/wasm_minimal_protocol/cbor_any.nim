
import ./cbor
import std/typeinfo

proc unreachable(s: string = "unreachable"){.noReturn.} =
  doAssert false, s
proc notImpl{.noReturn.} =
  raise newException(CborError, "not implemented for this type, when for Nim's Any type")

var cborAnyPool: seq[pointer]
proc collectCborAnyPool* =
  ## remember to call this proc at the end of your
  ##   typst-exported proc to avoid data overlap
  ## 
  ## For example:
  ## 
  ## ```Nim
  ## proc myExportedProc*(x: Any): string{.export_typst.} =
  ##   defer: collectCborAnyPool()
  ##   ...
  ## ```
  for p in cborAnyPool: dealloc(p)
  cborAnyPool.setLen(0)

proc cborPoolAlloc[T](val: T): ptr T =
  result = cast[ptr T](alloc(sizeof T))
  cborAnyPool.add(result)
  result[] = val

defineCborPair Any:
  case val.kind
  of akInt..akInt64: s.writeValue(val.getBiggestInt)
  of akUInt..akUInt64: s.writeValue(val.getBiggestUint)
  of akFloat..akFloat128: s.writeValue(val.getBiggestFloat)
  of akString: s.writeValue(val.getString)
  else:
    notImpl()
do:
  proc toAny[T: not var](x: T): Any =
    ## toAny for rvalues
    let p = cborPoolAlloc x
    toAny(p[])
  var v: CborValueRef
  s.readValue(v)
  val = case v.kind:
  of CborValueKind.Float:
    v.floatVal.toAny
  of CborValueKind.Simple:
    let sv = v.simpleVal
    template ltoAny(lit): Any =
      var `g lit`{.global.} = lit
      `g lit`.toAny
    const nilp = pointer nil
    if sv.isFalse: false.ltoAny
    elif sv.isTrue: true.ltoAny
    elif sv.isNull: nilp.ltoAny
    elif sv.isUndefined: nilp.ltoAny
    else: unreachable()
  of CborValueKind.Unsigned:
    let num = v.numVal.integer
    num.toAny
  of CborValueKind.Negative:
    let num = v.numVal.integer
    if num < high typeof num:
      let un = -int64(num+1)
      un.toAny
    else:
      let f = -1.0 - num.float
      f.toAny
  of CborValueKind.String:
    v.strVal.toAny
  else:
    notImpl()



