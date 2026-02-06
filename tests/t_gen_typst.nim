
import wasm_minimal_protocol
import std/math

proc frexp(x: float): (float, int){.export_typst.} = math.frexp(x)
proc hypot(x, y: float): float{.export_typst.} = math.hypot(x, y)

genTypstFile()
