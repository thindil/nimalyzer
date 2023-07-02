discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule ifstatements requires at maximum 0 options, but 1 provided: 'randomoption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: if statement, line: 1 the if statement starts with a negative condition.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: if statement, line: 1 the if statement branch doesn't contain only discard statement.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: if statement, line: 1 the if statement branch contains only discard statement.
INFO: The test for searching for invalid code is disabled.
INFO: Checking search type of the rule with the valid code.
NOTICE: if statement, line: 1 the if statement branch contains only discard statement.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: If statements which can't be upgraded not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: if statement, line: 1 the if statement doesn't start with a negative condition.
INFO: Checking count type of the rule with the invalid code.
NOTICE: If statements which can be upgraded found: 1
INFO: Checking count type of the rule with the valid code.
NOTICE: If statements which can be upgraded found: 0
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: if statement, line: 1 the if statement doesn't start with a negative condition.
NOTICE: If statements which can't be upgraded found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: If statements which can't be upgraded found: 0
INFO: Checking fix type of the rule.
ERROR: if statement, line: 1 the if statement starts with a negative condition.
INFO: Checking negative fix type of the rule.
INFO: The tests for negative fix type of rule are disabled.'''
"""

import ../../src/rules/ifstatements
import ../helpers.nim

const
  validOptions: seq[string] = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "if a != 1: echo \"not equal\" else: echo \"equal\""
  validNimCode = "if a == 1: echo \"equal\" else: echo \"not equal\""

runRuleTest(disabledChecks = {negativeFix, invalidSearch})
