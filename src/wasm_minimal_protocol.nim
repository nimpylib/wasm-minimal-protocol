import std/macros

import wasm_minimal_protocol/wasi

proc wasm_minimal_protocol_write_args_to_buffer(buffer: pointer){.importc, codegenDecl: typst_env_decl.}
proc wasm_minimal_protocol_send_result_to_host(buffer: pointer, length_of_buffer: Size){.importc, codegenDecl: typst_env_decl.}

##[
proc (a1, a2, ..., an) -> `if failed` (int32)
]##

template send_result(s) =
  wasm_minimal_protocol_send_result_to_host(s[0].addr, Size s.len)

proc isByteOpenArray(n: NimNode): bool =
  if n.kind != nnkBracketExpr or n.len != 2:
    return
  let head = n[0]
  if not (head.eqIdent"openArray" or head.eqIdent"seq"): return
  let ele = n[1]
  result = ele.eqIdent"char" or
    ele.eqIdent"byte" or ele.eqIdent"uint8"

macro export_typst_bytes*(def) =
  let ori_prc_id = def.name
  var nname = ori_prc_id
  var exportcPragma = ident"exportc"
  let params = def.params
  let nIdentDefsp1 = params.len
  let nIdentDefs = nIdentDefsp1 - 1
  let infResBody = newStmtList()
  let sufResBody = newStmtList()
  let resParams = params.copyNimNode

  let bufId = genSym(nskLet, "buffer")
  resParams.add bindSym"Size"  # resType
  let call = newCall ori_prc_id

  let totLensId = ident("totLens")

  var nargs = 0
  for i in 1..nIdentDefs:  # params[0] is resType
    # a0, a1, ...
    let e = params[i]
    let lastIdx = e.len - 1
    let lastIdx2 = lastIdx - 1
    let eType = e[lastIdx2]
    if not (eType.kind == nnkEmpty or
        eType.eqIdent"string" or eType.isByteOpenArray):
      error "only string or byte-seq-like args allowed for this macro", eType
    if e[lastIdx].kind != nnkEmpty:
      error "no default args allowed currently", e[i+1]
      #TOOD:defval, aware in typst
    for j in 0..<lastIdx2:
      nargs += 1
      let id = genSym(nskParam, "a" & $nargs)
      resParams.add newIdentDefs(id, bindSym"Size")
      let ne = ident e[j].strVal
      let nargs1s = newIntLitNode(nargs - 1)
      let totLenI1s = quote do: `totLensId`[`nargs1s`]
      infResBody.add quote do:
        `totLensId`[`nargs`] = `totLenI1s` + `id`
      call.add ne
      sufResBody.add quote do:
        var `ne` = newString(`id`)
        copyMem(`ne`[0].addr,
                cast[pointer](cast[int](`bufId`) + `totLenI1s`),
                `id`
        )
  
  let resBody = newStmtList()
  let nargsp1 = nargs + 1
  let final = if nargs == 0:
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
    let totLen = quote do: `totLensId`[`nIdentDefs`]
    infResBody.add quote do:
      let `bufId` = alloc(`totLen`)
      wasm_minimal_protocol_write_args_to_buffer(`bufId`)
    resBody.add quote do:
      var `totLensId`: array[`nargsp1`, `Size`]
      # an acc sum len
      # #0 is 0
    newCall("dealloc", bufId)

  resBody.add infResBody
  resBody.add sufResBody

  resBody.add quote do:
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
  ndef.add resBody
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
  proc f(s, s2: string): string{.export_typst_bytes.} =
    s & '+' & s2 & '$'
  proc f_tot_len_expr(s, s2: openArray[char]): string{.export_typst_bytes.} =
    $s.len & '+' & $s2.len

  proc hello(): string{.export_typst_bytes.} =
    "hello from Nim"

