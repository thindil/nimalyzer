# Count: 3
# Negative count: 0

type
  test = object
    case t: char
    of 'a':
      a: char
    else:
      d: int8
    b, c: char
  TestError = object of CatchableError

using
  dontCheck: ref test
