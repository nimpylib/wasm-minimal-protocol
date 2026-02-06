
#{
  let p = plugin("../bin/t_min_s.wasm")
  let _ = p.wasm_minimal_protocol_NimMain()
  let bh = p.hello()
  let bf = p.f(bytes("ab"), bytes("asd"))

  assert(str(bh) == "hello from Nim")
  assert(str(bf) == "ab+asd$")
  assert(
    p.f_tot_len_expr(bytes("123"), bytes("45")) ==
    bytes("3+2")
  )

  // typed argument
  let eq(res, f, ..args) = {
    let arr = ()
    for i in args.pos() {
      arr.push(cbor.encode(i))
    }
    assert(res == cbor(f(..arr)))
  }
  eq(
    4.6, p.add, 1.2, 3.4
  )
  eq(
    (0.6, 1),
    p.myfrexp, 1.2
  )
  eq(
    15,
    p.binom, 6, 2
  )

}
