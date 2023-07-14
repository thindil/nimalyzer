discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule forstatements requires at maximum 1 options, but 2 provided: 'randomoption, anotheroption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: for statement, line: 1 don't use 'pairs' or 'items' for iterators.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: for statement, line: 1 uses 'items' for iterators.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: For statements which can be upgraded not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: for statement, line: 1 don't use 'pairs' or 'items' for iterators.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: For statements which can't be upgraded not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: for statement, line: 1 uses '' for iterators.
INFO: Checking count type of the rule with the invalid code.
NOTICE: For statements which can be upgraded found: 1
INFO: Checking count type of the rule with the valid code.
NOTICE: For statements which can be upgraded found: 0
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: For statements which can't be upgraded found: 0
INFO: Checking negative count type of the rule with the valid code.
NOTICE: for statement, line: 1 uses 'items' for iterators.
NOTICE: For statements which can't be upgraded found: 1
INFO: Checking fix type of the rule.
ERROR: for statement, line: 1 don't use 'pairs' or 'items' for iterators.
INFO: Checking negative fix type of the rule.
ERROR: for statement, line: 1 uses 'items' for iterators.'''
"""

import ../../src/rules/forstatements
import ../helpers.nim

const
  validOptions: seq[string] = @["iterators"]
  invalidOptions = @["randomoption", "anotheroption"]
  invalidNimCode = "for i in [1 .. 6]: echo i"
  validNimCode = "for i in [1 .. 6].items: echo i"

runRuleTest()
