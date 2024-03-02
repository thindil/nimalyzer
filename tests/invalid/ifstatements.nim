let a = 0

if a != 1:
  echo "not equal"
else:
  echo "equal"

if a == 0:
  discard

if a == 0:
  echo "zero"
elif a == 1:
  echo "one"
elif a == 2:
  echo "two"
else:
  echo "more"

when sizeof(int) == 2:
  echo "running on a 16 bit system!"
elif sizeof(int) == 4:
  echo "running on a 32 bit system!"
elif sizeof(int) == 8:
  echo "running on a 64 bit system!"
else:
  echo "cannot happen!"
