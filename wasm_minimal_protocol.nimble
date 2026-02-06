# Package

version       = "0.1.1"
author        = "litlighilit"
description   = "A minimal protocol to write typst plugins."
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
binDir        = "bin"
const mainBin = "nim-typst-plugin"
namedBin["wasm_minimal_protocol"] = mainBin


# Dependencies

requires "nim >= 2.0.8"
when defined(cborious):
  requires "cborious"
else:
  requires "cbor_serialization"


var pylibPre = "https://github.com/nimpylib"
let envVal = getEnv("NIMPYLIB_PKGS_BARE_PREFIX")
if envVal != "": pylibPre = ""
elif pylibPre[^1] != '/':
  pylibPre.add '/'
template pylib(x, ver) =
  requires if pylibPre == "": x & ver
           else: pylibPre & x

pylib "wasm_backend", " ^= 0.1.2"

task test, "test, assuming `nimble build` has been run":
  #taskWithArgs buildWasmLib, "build .wasm(wasi) library":
  let testDir = "tests/"
  let name = "t_examples"
  let nameBase = testDir & name
  let res = gorgeEx(binDir & '/' & mainBin & ' ' & nameBase & " -O:" & binDir)
  if res.exitCode != 0:
    quit res.output

  exec "typst c --root . " & nameBase & ".typ"
  echo "[ok] minimal test passed"
  rmFile nameBase & ".pdf"

