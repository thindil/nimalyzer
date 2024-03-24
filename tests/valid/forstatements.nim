# Count: 0
# Negative count: 2

for i in [1 .. 6].items:
  echo i
  if i > 0:
    if i == 1:
      continue
    for j in [1 .. 6].items:
      echo j
