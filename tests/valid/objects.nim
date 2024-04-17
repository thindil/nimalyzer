# Count: 0
# Negative count: 2

type
  test = object
    case t*: char
    of 'a':
      a*: int
    else:
      d*: int
    b, c: char
