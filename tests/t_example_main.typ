
#import "t_example_lib.typ": *

#{
  let eq = assert.eq
  eq(
    format-size(4096, includeSpace: true),
    "4 KiB"
  )
  eq(
    hypot(3.0, 4.0), 5
  )
  eq(
    str-count("123_456__653", "_"),
    3
  )
  // hello()
  eq(
    rune-len("a😀c"), 3
  )
  eq(
    with-default-args(4, b: 2),
    "a=4, b=2, c=default"
  )
  eq(
    n-format("hello $#, and $#", ("Tim", "Lily")),
    "hello Tim, and Lily"
  )
  eq(
    n-format-v("hello $#, and $#", "Tim", "Lily"),
    "hello Tim, and Lily"
  )
}
