proc wasm_decl*(module: string): string = "__attribute__((__import_module__(\"" & module & """"), __import_name__("$2")))
$1 $2$3
"""
const typst_env_decl* = wasm_decl"typst_env"

type Errno* = int32
type charp* = ptr uint8
type Pointer* = int32
type Size* = int32

