discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule namingconv requires at least 2 options, but only 0 provided: ''.
INFO: Checking check type of the rule with the invalid code.
ERROR: name of 'IsThe' line: 1 doesn't follow naming convention.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: name of 'isThe' line: 1 follow naming convention.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: Declarations which follow naming convention not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: name of 'isThe' line: 1 follow naming convention.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: Declarations which not follow naming convention not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: name of 'IsThe' line: 1 doesn't follow naming convention.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Declarations which follow naming convention found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Declarations which follow naming convention found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: name of 'IsThe' line: 1 doesn't follow naming convention.
NOTICE: Declarations which not follow naming convention found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Declarations which not follow naming convention found: 0
INFO: Checking fix type of the rule.
INFO: The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/namingconv
import ../helpers.nim

const
  validOptions = @["variables", "[a-z][a-zA-Z0-9_]"]
  invalidOptions = @[]
  invalidNimCode = "var IsThe: int = 1"
  validNimCode = "var isThe: int = 1"

runRuleTest(disabledChecks = {fixTests})
