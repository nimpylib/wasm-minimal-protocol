# Package

version       = "0.1.0"
author        = "litlighilit"
description   = "A minimal protocol to write typst plugins."
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["wasm_minimal_protocol"]


# Dependencies

requires "nim >= 2.0.8"
requires "cbor_serialization"


var pylibPre = "https://github.com/nimpylib"
let envVal = getEnv("NIMPYLIB_PKGS_BARE_PREFIX")
if envVal != "": pylibPre = ""
elif pylibPre[^1] != '/':
  pylibPre.add '/'
template pylib(x, ver) =
  requires if pylibPre == "": x & ver
           else: pylibPre & x

pylib "wasm_backend", " ^= 0.1.1"

task testMin, "minimal test":
  #taskWithArgs buildWasmLib, "build .wasm(wasi) library":
  let res = gorgeEx("nim-wasm-build-flags  --export-all=false " & NimVersion, cache=NimVersion)
  if res.exitCode != 0:
    quit res.output
  let cmd = "c " & res.output & " -u:nimPreviewSlimSystem --hints:off "

  let name = "t_min"
  let o = "bin/" & name & ".wasm"
  selfExec cmd & " -o:" & o & ' ' & srcDir & "/" & bin[0]
  let resStub = gorgeEx("wasi-stub " & o & " -o bin/" & name & "_s.wasm")
  if resStub.exitCode != 0:
    quit resStub.output
  let outPre = "tests/" & name
  exec "typst c --root . " & outPre & ".typ"
  echo "[ok] minimal test passed"
  rmFile outPre & ".pdf"

