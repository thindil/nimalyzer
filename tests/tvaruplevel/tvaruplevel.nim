discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule varuplevel requires at maximum 0 options, but 1 provided: 'something'.
INFO: Checking check type of the rule with the invalid code.
ERROR: declaration of 'b' line: 3 can be updated to constant.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: declaration of a line: 1 can't be updated to let.
INFO: Checking negative check type of the rule with the invalid code.
ERROR: declaration of a line: 1 can't be updated to let.
INFO: Checking search type of the rule with the invalid code.
NOTICE: declaration of a line: 1 can't be updated to let.
INFO: The test for searching for invalid code is disabled.
INFO: Checking search type of the rule with the valid code.
NOTICE: declaration of a line: 1 can't be updated to let.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: Declarations which can't be upgraded not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: declaration of 'b' line: 3 can be updated to constant.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Declarations which can be upgraded found: 1
INFO: Checking count type of the rule with the valid code.
NOTICE: Declarations which can be upgraded found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: declaration of 'b' line: 3 can be updated to constant.
NOTICE: Declarations which can't be upgraded found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Declarations which can't be upgraded found: 0
INFO: Checking fix type of the rule.
ERROR: declaration of 'b' line: 3 can be updated to constant.
INFO: Checking negative fix type of the rule.
INFO: The tests for negative fix type of rule are disabled.'''
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
