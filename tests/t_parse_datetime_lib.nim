# typst lacks datetime parsing, like `datetime.parse`

import wasm_minimal_protocol
import std/times

type TypstDatetimeDict = object
  year, month, day, hour, minute, second: int

when true:  # define toTypst for DateTime
  import std/macros
  macro getattr(obj; field: static[string]): untyped = newDotExpr(obj, ident field)
  template day(dt: DateTime): int = dt.monthday
  func toTypst(res: DateTime): TypstDatetimeDict =
    for k, v1 in fieldPairs(result):
      v1 = typeof(v1) getattr(res, k)

func parseDatetime(x: string, format = "yyyy-M-d'T'H:m:s"): TypstDatetimeDict{.
    dispatchTypst: "datetime", export_typst: "datetime-parse".} =
  ## ref https://nim-lang.org/docs/times.html#parsing-and-formatting-dates
  ##   for `format` syntax
  if 'z' in format:
    raise newException(ValueError, "typst plugin cannot be aware of timezone")
  # We known `parse`'s impurity is only about timezone,
  #   so we use `{.noSideEffect.}` pragma to tell Nim compiler it's no longer impure.
  {.noSideEffect.}:
    parse(x, format).toTypst()


genTypstFile()
