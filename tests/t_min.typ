// This is to be run when `nimble testMin`.
//  ref ../src/wasm_minimal_protocol.nim's
//   `when isMainModule` for nim side code.
#{
  let p = plugin("../bin/t_min_s.wasm")
  let _ = p.wasm_minimal_protocol_NimMain()

  let eq(res, res1) = assert(res == res1)
  { // test bytes-target-function
    let bh = p.hello()
    let bf = p.f(bytes("ab"), bytes("asd"))
    eq(str(bh), "hello from Nim")
    eq(str(bf), "ab+asd$")
    eq(
      p.f_tot_len_expr(bytes("123"), bytes("45")),
      bytes("3+2")
    )

  }

  // typed argument
  let bind(f) = (..args) => {
    let arr = ()
    for i in args.pos() { arr.push(cbor.encode(i)) }
    cbor(f(..arr))
  }

  let add = bind(p.add)
  let frexp = bind(p.frexp)
  let binom = bind(p.binom)

  eq(4.6, add(1.2, 3.4))
  eq(frexp(1.2), (0.6, 1))
  eq(binom(6, 2), 15)

}
