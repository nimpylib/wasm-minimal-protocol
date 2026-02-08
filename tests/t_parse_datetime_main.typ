
#{
  import "t_parse_datetime_lib.typ": *
  let res = parse-datetime("2025-03-20T01:02:03")

  assert(res == (year: 2025, month: 3, day: 20, hour: 1, minute: 2, second: 3))

  // construct datetime:
  let dt = datetime(..res)
  assert(dt.day() == res.day)

}
