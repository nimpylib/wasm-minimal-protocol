
import wasm_minimal_protocol
import std/[math, strutils]


export_typst_from `%`, "n-format", proc (fmt: string, args: openArray[string]): string{.noSideEffect.}
export_typst_from format, "n-format-v", proc (fmt: string, args: varargs[string]): string{.noSideEffect.}

genTypstFile()
