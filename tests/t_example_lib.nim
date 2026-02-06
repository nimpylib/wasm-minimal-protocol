
import wasm_minimal_protocol
import std/[math, strutils, unicode, strformat]

proc frexp(x: float): (float, int){.export_typst.} = math.frexp(x)
proc hello(): string{.export_typst.} = "hello from Nim"
proc str_count(s, sub: string): int{.export_typst.} = s.count(sub)
proc runeLen(s: string): int{.export_typst.} = unicode.runeLen(s)
proc hypot(x, y: float): float{.export_typst.} = math.hypot(x, y)

proc withDefaultArgs(a: int, b: int = 42, c: string = "default"): string{.export_typst.} =
  &"a={a}, b={b}, c={c}"

genTypstFile()
when isMainModule:
  echo hello()
