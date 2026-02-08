
import std/macros
import std/strutils
import ./[wasi, cbor, typst_gen_decl]
export cbor
when gen_t:
  import std/macrocache
  import ./typst_literal_gen
  export macrocache.pairs

proc wasm_minimal_protocol_write_args_to_buffer(buffer: pointer){.importc, codegenDecl: typst_env_decl.}
proc wasm_minimal_protocol_send_result_to_host(buffer: pointer, length_of_buffer: Size){.importc, codegenDecl: typst_env_decl.}

##[
proc (a1, a2, ..., an) -> `if failed` (int32)
]##

template send_result(s) =
  wasm_minimal_protocol_send_result_to_host(s[0].addr, Size s.len)

when gen_t:
  proc isExactOpenArrayOrVarargs(n: NimNode, ele: var NimNode, isVarargs: var bool): bool =
    if n.kind != nnkBracketExpr or n.len != 2: return
    let head = n[0]
    isVarargs = if head.eqIdent"openArray": false
    elif head.eqIdent"varargs": true
    else:
      return
    result = true
    ele = n[1]

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

template formatTypstResult*(f: string){.pragma.}  ## `f` shall contains `$1` to reference the original return value
template dispatchTypst*(typstCallback: string){.pragma.}  ## `typstCallback` is a typst function name
when gen_t:
  const collectTypstExports* = CacheTable"wasm_minimal_protocol_typst_exports"

  proc getTypstResFmt(def: NimNode): string =
    result = "$1"
    for p in def.pragma:
      if p.kind == nnkExprColonExpr:
        let (head, val) = (p[0], p[1])
        if head.eqIdent"dispatchTypst": return val.strVal & "(..($1))"
        if head.eqIdent"formatTypstResult": return val.strVal

proc check_noSideEffect(def: NimNode) =
  var noSideEffect = false
  if def.kind == nnkFuncDef:
    noSideEffect = true
  else:
    if def.kind != nnkProcDef:
      error "only proc or func can be exported to typst, but got " & $def.kind, def
    if def.pragma.findChild(it.eqIdent"noSideEffect") != nil:
      noSideEffect = true

  if not noSideEffect:
    warning """only noSideEffect proc (aka. func) is guaranteed to always work properly in typst,
please consider to change `proc` to `func` or add {.noSideEffect.} pragma if possible.
ref plugin.transition in https://typst.app/docs/reference/foundations/plugin/ for details""", def

type
  NameConvention* = enum
    ncAsIs     ## export with the same name as Nim proc
    ncKebab    ## export with kebab-case name
    # ncSnake    ## export with snake_case name
    # ncPascal   ## export with PascalCase name

const ncTypst* = ncKebab

proc toKebabCase(s: string): string =
  ## for effectivity, only care ASCII cases
  result = newStringOfCap(s.len+1)
  for c in s:
    result.add case c
    of 'A'..'Z':
      if result.len > 0:
        result.add '-'
      c.toLowerAscii
    of '_': '-'
    else: c

const exportNimDocToTypst*{.booldefine.} = true
proc export_typst_impl(result: NimNode, def: NimNode; bytesOnly: bool, export_name: string|NameConvention = "") =
  when gen_t:
    var curParamNames = newNimNode nnkFormalParams
    var doc: NimNode = nil
    let resFormat = getTypstResFmt(def)
    when exportNimDocToTypst:
      let body1 = def.body[0]
      if body1.kind == nnkCommentStmt:
        doc = body1
  let ori_prc_id = def.name

  let ori_prc_name = ori_prc_id.strVal
  let nname = genSym(nskProc, "typst_exported_" & ori_prc_name)
  let export_wasm_name = when export_name is string:
    if export_name == "": ori_prc_name else: export_name
  else:
    case export_name
    of ncAsIs: ori_prc_name
    of ncTypst: ori_prc_name.toKebabCase
  let exportcPragma = ident"exportc"
  let exportPragma = nnkExprColonExpr.newTree(
    ident"codegenDecl",
    newCall(bindSym"export_wasm_decl",
      newStrLitNode export_wasm_name
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
    var eType = e[lastIdx2]
    if bytesOnly:
      if not (eType.kind == nnkEmpty or
          eType.isStrLike):
        error "only string or byte-seq-like args allowed for this macro", eType
    let defval = e[lastIdx]
    
    template has_defval: bool = defval.kind != nnkEmpty
    template no_defval =
      if has_defval:
        error "no default args allowed here", defval
    when gen_t:
      var isVarargs = false
      var typstExpr: NimNode
      if bytesOnly:
        no_defval
      else:
        if has_defval:
          typstExpr = newStrLitNode toTypst defval
          if eType.kind == nnkEmpty:
            eType = newCall("typeof", defval)
        # to support openArray[T] and varargs[T] (convert it to seq[T])
        var ele: NimNode
        if eType.isExactOpenArrayOrVarargs(ele, isVarargs):
          eType = if ele.eqIdent"char" and not isVarargs:
            ident"string"
          else:
            nnkBracketExpr.newTree(ident"seq", ele)
    else:
      no_defval

    for j in 0..<lastIdx2:
      nargs += 1
      let id = genSym(nskParam, "a" & $nargs)
      resParams.add newIdentDefs(id, bindSym"Size")
      let ne = ident e[j].strVal
      when gen_t:
        curParamNames.add:
          if isVarargs: nnkPrefix.newTree(ident"*", ne)
          else:
            if isVarargs:  # previous is varargs, current is not varargs, not supported,
              # kw-only args, not supported yet
              error "kw-only args not supported yet", ne
            nnkExprEqExpr.newTree(ne, typstExpr)
      let nargs1s = newIntLitNode(nargs - 1)
      let totLenI1s = quote do: `totLensId`[`nargs1s`]
      infResBody.add quote do:
        `totLensId`[`nargs`] = `totLenI1s` + `id`
      call.add ne

      let neStr = if not bytesOnly:
        ident "str" & ne.strVal
      else: ne
      sufResBody.add quote do:
        var `neStr` = newString(`id`)
        copyMem(`neStr`[0].addr,
                cast[pointer](cast[int](`bufId`) + `totLenI1s`),
                `id`
        )
      if not bytesOnly:
        let Cbor_decodeId = bindSym"Cbor_decode"
        sufResBody.add quote do:
          let `ne` = try:
            `Cbor_decodeId`(`neStr`, typeof(`eType`))
          except CborError as e:
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

  if not bytesOnly:
    let Cbor_encodeId = bindSym"Cbor_encode"
    call = quote do:
      `Cbor_encodeId`(`call`)
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
  when gen_t:
    collectTypstExports[export_wasm_name] = nnkBracket.newTree(
      curParamNames, doc, newStrLitNode resFormat)

const wasm = defined(wasm)
template export_pragma_impl(def; bytesOnly: bool, export_name: untyped = "") =
  def.check_noSideEffect()
  when wasm:
    result = newStmtList(def)
    result.export_typst_impl(def, bytesOnly, export_name)
  else:
    def.addPragma ident"used"
    result = def

macro export_typst_bytes*(def) = export_pragma_impl(def, bytesOnly=true)
macro export_typst_bytes_as*(name: static[string]; def) = export_pragma_impl(def,
  bytesOnly=true, export_name=name)
macro export_typst*(def) =
  runnableExamples:
    func hello: string{.export_typst.} = "hello"
  export_pragma_impl(def, bytesOnly=false)
macro export_typst_as*(name: static[string], def) =
  runnableExamples:
    func hello: string{.export_typst_as"hello-from-nim".} = "hello"
  export_pragma_impl(def, bytesOnly=false, export_name=name)
macro export_typst_conv*(name: static[NameConvention], def) =
  export_pragma_impl(def, bytesOnly=false, export_name=name)

template export_typst_fromImpl{.dirty.} =
  let defImpl = def.getImpl()
  defImpl.check_noSideEffect()
  result = newStmtList()
  when wasm:
    result.export_typst_impl(defImpl, bytesOnly=false, export_name=export_name)
macro export_typst_from*(def: proc, export_name: static[string] = "") =
  runnableExamples:
    import std/editdistance as libed
    export_typst_from editDistance, "nim-edit-distance"
    export_typst_from editDistance, ncTypst  # export as `edit-distance`
    import std/unidecode
    export_typst_from unidecode.unidecode
    # unidecode("北京") == "Bei Jing "
  export_typst_fromImpl
macro export_typst_from*(def: proc, export_name: static[NameConvention]) =
  export_typst_fromImpl

