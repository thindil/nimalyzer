discard """
  exitcode: 0
  output: '''FATAL The rule varuplevel requires at maximum 0 options, but 1 provided: 'something'.
ERROR declaration of 'b' line: 3 can be updated to constant.
ERROR declaration of a line: 1 can't be updated to let.
ERROR declaration of a line: 1 can't be updated to let.
NOTICE declaration of a line: 1 can't be updated to let.
The test for searching for invalid code is disabled.
NOTICE declaration of a line: 1 can't be updated to let.
NOTICE Declarations which can't be upgraded not found.
NOTICE declaration of 'b' line: 3 can be updated to constant.
NOTICE Declarations which can be upgraded found: 1
NOTICE Declarations which can be upgraded found: 1
NOTICE declaration of 'b' line: 3 can be updated to constant.
NOTICE Declarations which can't be upgraded found: 1
NOTICE Declarations which can't be upgraded found: 0
ERROR declaration of 'b' line: 3 can be updated to constant.
The tests for negative fix type of rule are disabled.'''
"""

import ../../src/rules/varuplevel
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["something"]
  invalidNimCode = """
var a: seq[int]
a.add(1)
let b: int = 3"""
  validNimCode = """
var a: seq[int]
a.add(1)
const b: int = 3"""

runRuleTest(disabledChecks = {invalidSearch, negativeFix})
