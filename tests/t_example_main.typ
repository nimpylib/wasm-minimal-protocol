
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
}
