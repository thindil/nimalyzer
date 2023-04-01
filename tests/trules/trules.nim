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

var options = RuleOptions(options: @[], parent: true, fileName: "",
    negation: false, ruleType: check, amount: -1, enabled: true)
showSummary(options, "Things found:", "Things not found.")
assert options.amount == 0

setResult(true, options, "Myproc line 10: found", "Myproc line 10: not found")
assert options.amount == 1

assert validateOptions("Test Rule", @["1"], @[integer], @[], 1)
assert not validateOptions("Test rule", @["a"], @[RuleOptionsTypes.string, integer], @[], 2)
