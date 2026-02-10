
import std/strutils

proc toKebabCase*(s: string): string =
  ## for effectivity, only care ASCII cases
  result = newStringOfCap(s.len+1)
  for c in s:
    result.add case c
    of 'A'..'Z':
      if result.len > 0 and result[^1] != '-':
        result.add '-'
      c.toLowerAscii
    of '_': '-'
    else: c

proc op2ident*(s: string): string =
  ## for effectivity, only care ASCII cases
  result = newStringOfCap(s.len)
  for c in s:
    template A(x) = result.add x
    case c
    of PunctuationChars - {'_'} + {' '}:
      case c
      of '!': A "Bang"
      of '"': A "Quote"
      of '#': A "Hash"
      of '$': A "Dollar"
      of '%': A "Percent"
      of '&': A "Amp"
      of '\'': A "SQuote"
      of '(': A "LParen"
      of ')': A "RParen"
      of '[': A "LBracket"
      of ']': A "RBracket"
      of '{': A "LBrace"
      of '}': A "RBrace"
      of '*': A "Star"
      of '+': A "Plus"
      of ',': A "Comma"
      of '-': A "Minus"
      of '.': A "Dot"
      of '/': A "Slash"
      # between is digits
      of ':': A "Colon"
      of ';': A "Semicolon"
      of '<': A "Less"
      of '=': A "Equal"
      of '>': A "Greater"
      of '?': A "Question"
      of '@': A "At"
      # between is uppercase letters
      of '\\': A "Backslash"
      of '^': A "Caret"
      # of '_': A "Underscore"
      of '`': A "Backtick"
      # between is lowercase letters
      of '|': A "Or"
      of '~': A "Tilde"
      of ' ': A "Space"
      else: doAssert false # unreachable
    else:
      result.add c
