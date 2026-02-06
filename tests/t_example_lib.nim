
import wasm_minimal_protocol
import std/[math, strutils, unicode]

proc frexp(x: float): (float, int){.export_typst.} = math.frexp(x)
proc hello(): string{.export_typst.} = "hello from Nim"
proc str_count(s, sub: string): int{.export_typst.} = s.count(sub)
proc runeLen(s: string): int{.export_typst.} = unicode.runeLen(s)
proc hypot(x, y: float): float{.export_typst.} = math.hypot(x, y)

genTypstFile()
when isMainModule:
  echo hello()
