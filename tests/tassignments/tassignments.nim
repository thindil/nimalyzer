discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule assignments requires at maximum 1 options, but 2 provided: 'randomoption, anotheroption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: assignments to 'i' line: 2 can be updated to a shorthand assignment.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: assignments to 'i' line: 2 can be updated to a full assignment.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: Assignments which are shorthand assigments not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: assignments to 'i' line: 2 is a shorthand assignment.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: Assignments which are't shorthand assigments not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: assignments to 'i' line: 2 is a full assignment.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Assignments which are shorthand assignment found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Assignments which are shorthand assignment found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: assignments to 'i' line: 2 is a full assignment.
NOTICE: Assignments which are't shorthand assignment found: 2
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Assignments which are't shorthand assignment found: 0
INFO: Checking fix type of the rule.
ERROR: assignments to 'i' line: 2 can be updated to a shorthand assignment.
INFO: Checking negative fix type of the rule.
ERROR: assignments to 'i' line: 2 can be updated to a full assignment.'''
"""

import ../../src/rules/assignments
import ../helpers.nim

const
  validOptions: seq[string] = @["shorthand"]
  invalidOptions = @["randomoption", "anotheroption"]
  invalidNimCode = """var i = 1
i = i + 1"""
  validNimCode = """var i = 1
i += 1"""

runRuleTest()
