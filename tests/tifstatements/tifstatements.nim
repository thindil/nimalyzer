discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule ifstatements requires at maximum 0 options, but 1 provided: 'randomoption'.
INFO: Checking check type of the rule.
ERROR: if statement, line: 1 the if statement starts with a negative condition.
INFO: Checking negative check type of the rule.
ERROR: if statement, line: 1 the if statement branch doesn't contain only discard statement.
ERROR: if statement, line: 1 the if statement branch doesn't contain only discard statement.
INFO: Checking search type of the rule.
NOTICE: if statement, line: 1 the if statement starts with a negative condition.
INFO: Checking negative search type of the rule.
NOTICE: if statement, line: 1 the if statement branch doesn't contain only discard statement.
NOTICE: if statement, line: 1 the if statement branch doesn't contain only discard statement.
INFO: Checking count type of the rule.
NOTICE: If statements which can be upgraded found: 1
NOTICE: If statements which can be upgraded found: 0
INFO: Checking negative type of the rule.
NOTICE: if statement, line: 1 the if statement branch doesn't contain only discard statement.
NOTICE: If statements which can't be upgraded found: 0
NOTICE: if statement, line: 1 the if statement branch doesn't contain only discard statement.
NOTICE: If statements which can't be upgraded found: 1
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

runRuleTest(disabledChecks = {negativeFix})
