# Package

version       = "0.1.2"
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
  for fp in listFiles(testDir):
    if not fp.endsWith(".typ"): continue
    let nameBase = fp[0..^5]
    var nimBase = nameBase
    if nameBase.endsWith"_main":
      nimBase = nimBase[0..^6] & "_lib"
    elif nameBase.endsWith"_lib": continue

    let res = gorgeEx(binDir & '/' & mainBin & ' ' & nimBase & " -O:" & binDir & " -d:gen_typst")
    if res.exitCode != 0:
      quit res.output

    exec "typst c --root . " & nameBase & ".typ"
    echo "[ok] " & nameBase & " passed"
    rmFile nameBase & ".pdf"

