
import std/[strutils, unicode, macros]

proc intLit*(n: SomeInteger): string = $n
proc charLit*(r: Rune): string =
  case r
  of '!'.Rune, '#'.Rune..'['.Rune,
      ']'.Rune..'~'.Rune:
    $r
  of Rune'\\': r"\\"
  of Rune'"': "\\\""
  of Rune'\n': r"\n"
  of Rune'\r': r"\r"
  of Rune'\t': r"\t"
  else:
    "\\u{" & toHex(r.uint32) & '}'
proc charLit*(c: char): string = charLit(Rune c)
proc strLit*(s: string): string =
  result.add '"'
  for r in s.runes:
    result.add charLit r
  result.add '"'

proc floatLit*(f: SomeFloat): string = $f

proc toTypst*(n: NimNode): string =
  result = case n.kind
  of nnkIntLit..nnkInt64Lit: intLit n.intVal
  of nnkCharLit:charLit Rune n.intVal
  of nnkStrLit: strLit n.strVal
  of nnkFloatLit..nnkFloat64Lit: floatLit n.floatVal
  of nnkBracket:
    var res = "("
    for i in 0 ..< n.len:
      res.add toTypst n[i]
      res.add ','
    res.add ')'
    res
  else:
    error "cannot convert to typst literal type", n
