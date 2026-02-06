## binary executable entry

import std/os
import std/osproc

import pkg/wasm_backend

proc findExeOrRaise(exe: string): string =
  result = findExe(exe)
  if result.len == 0:
    raise newException(ValueError, exe & " not found in PATH")

const options = {poEvalCommand, poStdErrToStdOut}
proc checked_run(cmd: string): string{.discardable.} =
  let tup = execCmdEx(cmd, options=options)
  if tup.exitCode != 0:
    raise newException(ValueError, "command failed: " & cmd & "\nOutput:\n" & tup.output)
  result = tup.output

proc compile*(nimSrcPath: string, outdir = "", nim = "") =
  ## `outdir` empty means same dir as `nimSrcPath`
  let wasm_args = get_wasm_build_flags(NimVersion)
  let nimExe = if nim == "": findExeOrRaise("nim") else: nim
  let cmd = nimExe & " c " & wasm_args & " -u:nimPreviewSlimSystem --hints:off "

  let wasmFile = (if outdir.len == 0:
    nimSrcPath.changeFileExt(".wasm")
  else:
    let (_, name, _) = nimSrcPath.splitFile()
    joinPath(outdir, name & ".wasm")
  ).quoteShell
  checked_run(cmd & " -o:" & wasmFile & ' ' & nimSrcPath.quoteShell)
  assert fileExists wasmFile

  let stubExe = findExeOrRaise("wasi-stub")
  checked_run(stubExe & " " & wasmFile & " -o " & wasmFile)
