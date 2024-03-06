# Count: 1
# Negative count: 0

let a = 0

if a == 1:
  echo "equal"
else:
  echo "not equal"

when sizeof(int) == 2:
  echo "running on a 16 bit system!"
elif sizeof(int) == 4:
  echo "running on a 32 bit system!"
elif sizeof(int) == 8:
  echo "running on a 64 bit system!"
else:
  echo "cannot happen!"
