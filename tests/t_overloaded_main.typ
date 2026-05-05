
#{
  import "t_overloaded_lib.typ": *
  let eq = assert.eq
  eq(
    n-format("hello $#, and $#", ("Tim", "Lily")),
    "hello Tim, and Lily"
  )
  eq(
    n-format-v("hello $#, and $#", "Tim", "Lily"),
    "hello Tim, and Lily"
  )

}
