let a = 0

if a != 1:
  echo "not equal"
elif a == 2:
  echo "equal to 2"
elif a == 3:
  echo "equal to 3"
else:
  echo "equal"

if a == 0:
  discard

when sizeof(int) == 2:
  echo "running on a 16 bit system!"
elif sizeof(int) == 4:
  echo "running on a 32 bit system!"
elif sizeof(int) == 8:
  echo "running on a 64 bit system!"
else:
  echo "cannot happen!"
