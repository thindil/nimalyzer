# Count: 0
# Negative count: 3

type
  test = object
    case t*: char
    of 'a':
      a*: int
    else:
      d*: int
    b, c: char

proc inittest(t: char, a: int): test =
  if t == 'a':
    result = test(t: 'a', a: a, b: 'a', c: 'a')
  else:
    result = test(t: 'b', d: a, b: 'b', c: 'b')
