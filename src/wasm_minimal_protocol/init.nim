
import ./wasi

template gen_wasm_init*(prcBody){.dirty.} =
  bind export_wasm_decl, Size
  proc wasm_minimal_protocol_NimMain*: Size{.exportc, cdecl,
      codegenDecl: export_wasm_decl("wasm_minimal_protocol_NimMain").} =
    prcBody
    0

