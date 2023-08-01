discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule casestatements requires at maximum 2 options, but 3 provided: 'randomoption, anotheroption, andmoreoption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: case statement, line: 1 the statement has less than 2 branches.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: case statement, line: 1 the statement doesn't have less than 2 branches.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: Case statements which can be upgraded not found.
INFO: The test for searching for invalid code is disabled.
INFO: Checking search type of the rule with the valid code.
NOTICE: case statement, line: 1 the statement has less than 2 branches.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: Case statements which can't be upgraded not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: case statement, line: 1 the statement doesn't have less than 2 branches.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Case statements which can be upgraded found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Case statements which can be upgraded found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: case statement, line: 1 the statement doesn't have less than 2 branches.
NOTICE: Case statements which can't be upgraded found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Case statements which can't be upgraded found: 0
INFO: Checking fix type of the rule.
INFO: The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/casestatements
import ../helpers.nim

const
  validOptions: seq[string] = @["min", "2"]
  invalidOptions = @["randomoption", "anotheroption", "andmoreoption"]
  invalidNimCode = """case a
  of 1:
    echo a"""
  validNimCode = """case a
  of 1:
    echo a
  of 2:
    echo a"""

runRuleTest(disabledChecks = {invalidSearch, fixTests})
