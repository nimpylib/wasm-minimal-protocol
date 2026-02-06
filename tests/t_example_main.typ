
#import "t_example_lib.typ": *

#{
  assert(
    hypot(3.0, 4.0) == 5
  )
  assert(
    str_count("123_456__653", "_")
    == 3
  )
  // hello()
  assert(
    runeLen("a😀c") == 3
  )
  assert(
    withDefaultArgs(4, b: 2)
    == "a=4, b=2, c=default"
  )
  assert(
    n-format("hello $#, and $#", ("Tim", "Lily"))
    == "hello Tim, and Lily"
  )
  assert(
    n-format-v("hello $#, and $#", "Tim", "Lily")
    == "hello Tim, and Lily"
  )
  let dt = parseDatetime("2025-03-20T01:02:03")
  let res = if (useCborious()) {
    (2025, 3, 20, 1, 2, 3)
  } else {
    (year: 2025, month: 3, day: 20, hour: 1, minute: 2, second: 3)
  }
  assert(dt == res)
}
