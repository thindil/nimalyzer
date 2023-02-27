discard """
  exitcode: 0
  outputsub: "Decrease value"
"""

import std/logging
import ../../src/rules
import ../helpers

setLogger()

var resultValue: int = 0

message("Decrease value", resultValue)
assert resultValue == -1
message("Increase value", resultValue, lvlInfo, false)
assert resultValue == 0

try:
  var i: int8 = int8.high
  i.inc
except:
  assert errorMessage("Reason: ", getCurrentException()) == 0
