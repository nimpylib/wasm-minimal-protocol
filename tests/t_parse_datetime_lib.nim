# typst lacks datetime parsing

import wasm_minimal_protocol
import std/times

type MyDateTime* = object
  year, month, day, hour, minute, second: int

import std/macros
macro getattr(obj; field: static[string]): untyped = newDotExpr(obj, ident field)
template day(dt: DateTime): int = dt.monthday
func parseDatetime(x: string, format = "yyyy-M-d'T'H:m:s"): MyDateTime =
  ## ref https://nim-lang.org/docs/times.html#parsing-and-formatting-dates
  ##   for format syntax
  if 'z' in format:
    raise newException(ValueError, "typst plugin cannot be aware of timezone")
  # We known `parse`'s impurity is only about timezone,
  #   so we use `{.noSideEffect.}` pragma to tell Nim compiler it's no longer impure.
  {.noSideEffect.}:
    let res = parse(x, format)
  for k, v1 in fieldPairs(result):
    v1 = typeof(v1) getattr(res, k)

export_typst_from parseDatetime, "parse-datetime"

genTypstFile()
