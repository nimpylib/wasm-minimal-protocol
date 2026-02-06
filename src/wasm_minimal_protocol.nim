
import ./wasm_minimal_protocol/[export_typst, wasi]
export export_typst

{.emit: """void NimMain();""".}
proc wasm_minimal_protocol_NimMain*: Size{.exportc, cdecl,
    codegenDecl: export_wasm_decl("wasm_minimal_protocol_NimMain").} =
  proc NimMain(){.importc, nodecl.}
  NimMain()
  0

when isMainModule:
  import std/parseopt
  import ./wasm_minimal_protocol/main
  var
    outdir = ""
    nimSrc = ""
    nim = ""

  for (kind, k, v) in getopt(shortNoVal = {'h'},
                             longNoVal = @["help"]):
    case kind
    of cmdEnd: doAssert false
    of cmdLongOption, cmdShortOption:
      case k
      of "outdir", "O":
        outdir = v
      of "help", "h":
        echo """Usage: wasm_minimal_protocol_compile [options] <nim_source_file>
Options:
  -O, --outdir <dir>    Output directory for the compiled wasm file
  -h, --help            Show this help message
"""       
        quit(0)
      of "nim":
        nim = v
      else:
        quit("Unknown option: " & k)
    of cmdArgument:
      if nimSrc != "":
        quit("Only one nim source file is allowed")
      nimSrc = k
  compile(nimSrcPath=nimSrc, outdir=outdir, nim=nim)

