
import std/[strutils, unicode, macros]

proc intLit*(n: SomeInteger): string = $n
proc charLitRaw(r: Rune): string =
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
template charLitImpl(c) =
  result.add '"'
  result.add charLitRaw(c)
  result.add '"'
proc charLit*(c: char): string = charLitImpl(Rune c)
proc charLit*(c: Rune): string = charLitImpl(c)
proc strLit*(s: string): string =
  result.add '"'
  for r in s.runes:
    result.add charLitRaw r
  result.add '"'

proc floatLit*(f: SomeFloat): string = $f

proc toTypst*(n: NimNode, toGetEnumType: NimNode = nil): string =
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
    let tk = toGetEnumType.getType.typeKind
    template cannotCvt(suf) =
      error "cannot convert to typst literal type from " & suf, n
    case tk
    of ntyBool:
      template eBool =
        cannotCvt "non-literal boolean"
      if n.kind == nnkIdent:
        if n.strVal == "true": "true"
        elif n.strVal == "false": "false"
        else: eBool
      else: eBool
    of ntyEnum:
      strLit $n
    of ntyNone:
      cannotCvt "non-typed value"
      # no type info, meaning not a `typed` arg
    else:
      cannotCvt "nim type kind " & $tk
