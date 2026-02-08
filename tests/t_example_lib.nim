
import wasm_minimal_protocol
import std/[math, strutils, unicode, strformat]

func frexp(x: float): (float, int){.export_typst.} = math.frexp(x)
func hello(): string{.export_typst.} = "hello from Nim"
func str_count(s, sub: string): int{.export_typst_conv(ncTypst).} = s.count(sub)
func runeLen(s: string): int{.export_typst_conv(ncTypst).} = unicode.runeLen(s)
func hypot(x, y: float): float{.export_typst.} = math.hypot(x, y)

func format(fmt: string, args: openArray[string]): string{.export_typst_as"n-format".} = fmt % args
func vformat(fmt: string, args: varargs[string]): string{.export_typst_as"n-format-v".} = fmt.format(args)


func withDefaultArgs(a: int, b: int = 42, c: string = "default"): string{.export_typst_conv(ncTypst).} =
  &"a={a}, b={b}, c={c}"

genTypstFile()

when isMainModule:
  echo hello()
