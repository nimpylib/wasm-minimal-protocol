
import ./wasm_minimal_protocol/[export_typst, wasi, typst_gen]
export export_typst, typst_gen

template imp_exp(name){.dirty.} =
  import ./wasm_minimal_protocol/name
  export name

when not defined(wasmCustomInit):
  imp_exp(init_def)
else:
  imp_exp(init)

when isMainModule:
  import std/parseopt
  import ./wasm_minimal_protocol/main
  var
    outdir = ""
    nimSrc = ""
    nim = ""
    additions = ""

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
      of "d", "define":
        additions.add " -d:" & v
      else:
        quit("Unknown option: " & k)
    of cmdArgument:
      if nimSrc != "":
        quit("Only one nim source file is allowed")
      nimSrc = k
  compile(nimSrcPath=nimSrc, outdir=outdir, nim=nim, additionalFlags=additions)

