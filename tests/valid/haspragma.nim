# Count: 2
# Negative count: 0

proc MyProc(a: int) {.raises: [].}

proc MyProc(a: int) =
  discard

proc MyProc2(a: int) {.raises: [].}=
  discard
