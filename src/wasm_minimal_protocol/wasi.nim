const base = "$1 $2$3"

proc attribute(attrs: string): string =
  "__attribute__((" & attrs & "))"
proc wasm_decl*(module: string): string =
  attribute("import_module(\"" & module & """"), import_name("$2")""") &
    base
const typst_env_decl* = wasm_decl"typst_env"

proc export_wasm_decl*(name: string): string =
  attribute("export_name(\"" & name & "\")") & base


type Errno* = int32
type charp* = ptr uint8
type Pointer* = int32
type Size* = int32

