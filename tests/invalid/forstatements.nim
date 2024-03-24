# Count: 2
# Negative count: 0

for i in [1 .. 6]:
  echo i
  if i > 0:
    if i == 1:
      continue
    for j in [1 .. 6]:
      echo j
