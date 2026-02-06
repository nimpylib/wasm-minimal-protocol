import std/macros

import wasm_minimal_protocol/wasi
import pkg/cbor_serialization

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
proc isStrLike(n: NimNode): bool =
  result = n.eqIdent"string" or n.isByteOpenArray

proc export_typst_impl(result: NimNode, def: NimNode; bytesOnly: bool) =
  let ori_prc_id = def.name

  let ori_name = ori_prc_id.strVal
  let nname = genSym(nskProc, "typst_exported_" & ori_name)
  let ori_prc_name = ori_prc_id.strVal
  let exportcPragma = nnkExprColonExpr.newTree(
    ident"exportc",
    newStrLitNode "wasm_minimal_protocol_" & ori_prc_name
  )
  let exportPragma = nnkExprColonExpr.newTree(
    ident"codegenDecl",
    newCall(bindSym"export_wasm_decl",
      newStrLitNode ori_prc_name
    )
  )
  let params = def.params
  let nIdentDefsp1 = params.len
  let nIdentDefs = nIdentDefsp1 - 1
  let infResBody = newStmtList()
  let sufResBody = newStmtList()
  let resParams = params.copyNimNode

  let bufId = genSym(nskLet, "buffer")
  resParams.add bindSym"Size"  # resType
  let resType = params[0]
  let resStrLike = resType.isStrLike
  if bytesOnly and not resStrLike:
    error "only string or byte-seq-like return type allowed for this macro", resType
  var call = newCall ori_prc_id

  let totLensId = ident("totLens")

  var nargs = 0
  for i in 1..nIdentDefs:  # params[0] is resType
    # a0, a1, ...
    let e = params[i]
    let lastIdx = e.len - 1
    let lastIdx2 = lastIdx - 1
    let eType = e[lastIdx2]
    var notStrLike = false
    if not (eType.kind == nnkEmpty or
        eType.isStrLike):
      if bytesOnly:
        error "only string or byte-seq-like args allowed for this macro", eType
      else:
        notStrLike = true
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

      let neStr = if notStrLike:
        ident "str" & ne.strVal
      else: ne
      sufResBody.add quote do:
        var `neStr` = newString(`id`)
        copyMem(`neStr`[0].addr,
                cast[pointer](cast[int](`bufId`) + `totLenI1s`),
                `id`
        )
      if notStrLike:
        sufResBody.add quote do:
          let `ne` = try:
            Cbor.decode(`neStr`, typeof(`eType`))
          except UnexpectedValueError as e:
            send_result(e.msg)
            return 1

  let resBody = newStmtList()
  let nargsp1 = nargs + 1
  let final = if nargs == 0:
    # no arg
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

  if not resStrLike:
    call = quote do:
      Cbor.encode(`call`)
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
  let ndef = newNimNode nnkProcDef
  ndef.add nname
  ndef.add emptyn # term rewrite
  ndef.add emptyn # generic params
  ndef.add resParams
  ndef.add nnkPragma.newTree(
    exportcPragma,
    exportPragma,
    ident"cdecl",
  )
  ndef.add emptyn # reversed
  ndef.add resBody
  result.add ndef

template export_pragma_impl(def; bytesOnly: bool) =
  result = newStmtList(def)
  result.export_typst_impl(def, bytesOnly)
macro export_typst_bytes*(def) = export_pragma_impl(def, bytesOnly=true)
macro export_typst*(def) = export_pragma_impl(def, bytesOnly=false)

macro export_typst_from*(def: proc) =
  result = newStmtList()
  result.export_typst_impl(def.getImpl(), bytesOnly=false)

{.emit: """void NimMain();""".}
proc wasm_minimal_protocol_NimMain*: Size{.exportc, cdecl,
    codegenDecl: export_wasm_decl("wasm_minimal_protocol_NimMain").} =
  proc NimMain(){.importc, nodecl.}
  NimMain()
  0

when isMainModule:
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

