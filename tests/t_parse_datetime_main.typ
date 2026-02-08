
#{
  import "t_parse_datetime_lib.typ": *
  let res = datetime-parse("2025-03-20T01:02:03")

  assert.eq(res,
    datetime(year: 2025, month: 3, day: 20,
             hour: 1, minute: 2, second: 3))

}
