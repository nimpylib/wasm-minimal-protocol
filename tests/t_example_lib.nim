
import wasm_minimal_protocol
import std/[math, strutils, unicode, strformat, times]

proc frexp(x: float): (float, int){.export_typst.} = math.frexp(x)
proc hello(): string{.export_typst.} = "hello from Nim"
proc str_count(s, sub: string): int{.export_typst.} = s.count(sub)
proc runeLen(s: string): int{.export_typst.} = unicode.runeLen(s)
proc hypot(x, y: float): float{.export_typst.} = math.hypot(x, y)

proc format(fmt: string, args: openArray[string]): string{.export_typst_as"n-format".} = fmt % args
proc vformat(fmt: string, args: varargs[string]): string{.export_typst_as"n-format-v".} = fmt.format(args)

type MyDateTime* = object
  year, month, day, hour, minute, second: int

# typst lacks datetime parsing
import std/macros
macro getattr(obj; field: static[string]): untyped = newDotExpr(obj, ident field)
template day(dt: DateTime): int = dt.monthday
proc parseDatetime(x: string, format = "yyyy-MM-dd'T'HH:mm:ss"): MyDateTime =
  let res = parse(x, format)
  for k, v1 in fieldPairs(result):
    v1 = typeof(v1) getattr(res, k)

proc useCborious: bool{.export_typst.} = defined(cborious)
#XXX: pkg/cborious convert nim's `object` to typst's array

export_typst_from parseDatetime

proc withDefaultArgs(a: int, b: int = 42, c: string = "default"): string{.export_typst.} =
  &"a={a}, b={b}, c={c}"

genTypstFile()
when isMainModule:
  echo hello()
