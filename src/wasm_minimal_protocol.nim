import std/macros

import wasm_minimal_protocol/wasi

proc wasm_minimal_protocol_write_args_to_buffer(buffer: pointer){.importc, codegenDecl: typst_env_decl.}
proc wasm_minimal_protocol_send_result_to_host(buffer: pointer, length_of_buffer: Size){.importc, codegenDecl: typst_env_decl.}

##[
proc (a1, a2, ..., an) -> `if failed` (int32)
]##

template send_result(s) =
  wasm_minimal_protocol_send_result_to_host(s[0].addr, Size s.len)

macro export_typst_bytes*(def) =
  let ori_prc_id = def.name
  var nname = ori_prc_id
  var exportcPragma = ident"exportc"
  let params = def.params
  let nargsp1 = params.len
  let nargs = nargsp1 - 1
  let infResBody = newStmtList()
  let sufResBody = newStmtList()
  let resParams = params.copyNimNode

  let bufId = genSym(nskLet, "buffer")
  resParams.add bindSym"Size"  # resType
  let call = newCall ori_prc_id

  let totLensId = genSym(nskVar, "totLens")
  infResBody.add quote do:
    var `totLensId`: array[`nargsp1`, `Size`]
    # an acc sum len
    # #0 is 0

  var id: NimNode
  for i in 1..nargs:  # params[0] is resType
    # a0, a1, ...
    let e = params[i]
    let eId = e[0]
    if not (e[2].kind == nnkEmpty or e[2].eqIdent"string"):
      error "shall be string", e[2]
    id = ident("a" & $i)
    resParams.add newIdentDefs(id, bindSym"Size")
    let ne = ident eId.strVal
    let i1s = i-1
    let totLenI1s = quote do: `totLensId`[`i1s`]
    infResBody.add quote do:
      `totLensId`[`i`] = `totLenI1s` + `id`
    call.add ne
    sufResBody.add quote do:
      var `ne` = newString(`id`)
      copyMem(`ne`[0].addr,
              cast[pointer](cast[int](`bufId`) + `totLenI1s`),
              `id`
      )
  
  let final = if id.isNil:
    # no arg, cannot overload
    let ori_name = ori_prc_id.strVal
    exportcPragma = nnkExprColonExpr.newTree(
      exportcPragma,
      newStrLitNode ori_name,
    )
    nname = genSym(nskProc, "typst_exported_" & ori_name)
    newStmtList()
  else:
    # if has arg
    let totLen = quote do: `totLensId`[`nargs`]
    infResBody.add quote do:
      let `bufId` = alloc(`totLen`)
      wasm_minimal_protocol_write_args_to_buffer(`bufId`)
    newCall("dealloc", bufId)

  infResBody.add sufResBody

  infResBody.add quote do:
    try:
      let res = `call`
      send_result(res)
      0
    except CatchableError as e:
      send_result(e.msg)
      1
    finally:
      `final`
  let emptyn = newEmptyNode()
  let ndef = def.copyNimNode
  ndef.add nname
  ndef.add emptyn # term rewrite
  ndef.add emptyn # generic params
  ndef.add resParams
  ndef.add nnkPragma.newTree(
    exportcPragma,
    ident"cdecl",
  )
  ndef.add emptyn # reversed
  ndef.add infResBody
  result = newStmtList(
    def,
    ndef
  )

{.emit: """void NimMain();""".}
proc wasm_minimal_protocol_NimMain*: Size{.exportc, cdecl.} =
  proc NimMain(){.importc, nodecl.}
  NimMain()
  0

when isMainModule:
  # mainly to ensure at least macro evaluation works
  proc f(s: string, s2: string): string{.export_typst_bytes.} =
    s & '+' & s2 & '$'

  proc hello(): string{.export_typst_bytes.} =
    "hello from Nim"
  
