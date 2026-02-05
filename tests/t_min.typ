
#import plugin("../bin/t_min_s.wasm"): f, wasm_minimal_protocol_NimMain, hello, f_tot_len_expr
#let _ = wasm_minimal_protocol_NimMain()
#let bh = hello()
#let bf = f(bytes("ab"), bytes("asd"))

#assert(str(bh) == "hello from Nim")
#assert(str(bf) == "ab+asd$")
#assert(
  f_tot_len_expr(bytes("123"), bytes("45")) ==
  bytes("3+2")
)
