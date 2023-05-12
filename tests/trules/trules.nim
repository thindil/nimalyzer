discard """
  exitcode: 0
  output: '''ERROR Decrease value
INFO Increase value
FATAL Reason: over- or underflow
FATAL The rule Test rule requires at least 2 options, but only 1 provided: 'a'.'''
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

assert validateOptions(RuleSettings(name: "Test Rule", options: @[integer],
    minOptions: 1), @["1"])
assert not validateOptions(RuleSettings(name: "Test rule", options: @[str,
    integer], minOptions: 2), @["a"])
