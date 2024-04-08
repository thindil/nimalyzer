# Count: 2
# Negative count: 0

const testArray: array[6, int] = [1, 2, 3, 4, 5, 6]

for i in testArray:
  echo i
  if i > 0:
    if i == 1:
      continue
    for j in testArray:
      echo j
