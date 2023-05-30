discard """
  exitcode: 0
  output: '''FATAL The rule varuplevel requires at maximum 0 options, but 1 provided: 'something'.
ERROR declaration of 'i' line: 1 can be updated to constant.
ERROR declaration of a line: 1 can't be updated to let.
NOTICE Declarations which can be upgraded not found.
NOTICE declaration of a line: 1 can't be updated to let.
NOTICE Declarations which can't be upgraded not found.
NOTICE declaration of 'i' line: 1 can be updated to constant.
NOTICE Declarations which can be upgraded found: 0
NOTICE Declarations which can be upgraded found: 1
NOTICE declaration of 'i' line: 1 can be updated to constant.
NOTICE Declarations which can't be upgraded found: 1
NOTICE Declarations which can't be upgraded found: 0
The tests for negative fix type of rule are disabled.'''
"""

import ../../src/rules/varuplevel
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["something"]
  invalidNimCode = "let i: int = 1"
  validNimCode = """
var a: seq[int]
a.add(1)"""

runRuleTest(disabledChecks = {negativeFix})
