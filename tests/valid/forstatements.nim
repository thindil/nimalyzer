# Count: 0
# Negative count: 2

const testArray: array[6, int] = [1, 2, 3, 4, 5, 6]

for i in testArray.items:
  echo i
  if i > 0:
    if i == 1:
      continue
    for j in testArray.items:
      echo j
