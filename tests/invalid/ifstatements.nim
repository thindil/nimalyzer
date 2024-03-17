# Count: 3
# Negative count: 1

let a = 0

if a != 1:
  echo "not equal"
else:
  echo "equal"

if a == 0:
  discard

if a > 0:
  for i in 1 .. 5:
    if a != 1:
      discard
    continue
