
import wasm_minimal_protocol
import std/math
# mainly to ensure at least macro evaluation works
proc f(s, s2: string): string{.export_typst_bytes.} =
  s & '+' & s2 & '$'
proc f_tot_len_expr(s, s2: openArray[char]): string{.export_typst_bytes.} =
  $s.len & '+' & $s2.len


proc gcdInts(arr: seq[int]): int{.export_typst.} = gcd arr

# we cannot use export_typst_from here
#  because math.frexp, hypot is overloaded
proc frexp(x: float): (float, int){.export_typst.} = math.frexp(x)
proc hypot(x, y: float): float{.export_typst.} = math.hypot(x, y)

#proc binom(n, k: int): int{.export_typst.} = math.binom(n, k)
export_typst_from math.binom

proc hello(): string{.export_typst_bytes.} =
  "hello from Nim"

