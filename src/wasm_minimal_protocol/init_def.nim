
import ./init

{.emit: """void NimMain();""".}
proc NimMain(){.importc, nodecl.}
gen_wasm_init NimMain()

