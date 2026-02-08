
import wasm_minimal_protocol
import std/[math, strutils, unicode, strformat]
from std/sugar import `->`

export_typst_from_func formatSize, ncTypst

func hello(): string{.export_typst.} = "hello from Nim"
func str_count(s, sub: string): int{.export_typst_conv(ncTypst).} = s.count(sub)

export_typst_from_func frexp, (x: float) -> (float, int)
export_typst_from_func hypot, proc (x, y: float): float

export_typst_from_func runeLen, ncTypst, string -> int

export_typst_from_func `%`,    "n-format",   (string, openArray[string]) -> string
export_typst_from_func format, "n-format-v", (string, varargs[string]) -> string


func withDefaultArgs(a: int, b = 42, c = "default"): string{.export_typst_conv(ncTypst).} =
  &"a={a}, b={b}, c={c}"

genTypstFile()

when isMainModule:
  echo hello()
