#{
  let p = plugin("../bin/t_raw_wasm_no_gen.wasm")
  let _ = p.wasm_minimal_protocol_NimMain()

  let eq = assert.eq
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

  let gcdInts = bind(p.gcdInts)
  let hypot = bind(p.hypot)
  let frexp = bind(p.frexp)
  let binom = bind(p.binom)

  eq(3, gcdInts((12, 3)))
  eq(5, hypot(3.0, 4.0))
  let res = frexp(1.2)
  assert(res == (frac: 0.6, exp: 1) or res == (0.6, 1))
  eq(binom(6, 2), 15)

}
