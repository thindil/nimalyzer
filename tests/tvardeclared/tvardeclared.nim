discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule vardeclared requires at least 1 options, but only 0 provided: ''.
INFO: Checking check type of the rule.
ERROR: declaration of 'i' line: 1 doesn't set type for the variable.
INFO: Checking negative check type of the rule.
ERROR: declaration of i line: 1 sets the type 'int' as the type of the variable.
INFO: Checking search type of the rule.
NOTICE: Declarations withtype declaration not found.
NOTICE: declaration of i line: 1 sets the type 'int' as the type of the variable.
INFO: Checking negative search type of the rule.
NOTICE: Declarations withouttype declaration not found.
NOTICE: declaration of 'i' line: 1 doesn't set type for the variable.
INFO: Checking count type of the rule.
NOTICE: Declarations withtype declaration found: 0
NOTICE: Declarations withtype declaration found: 1
INFO: Checking negative type of the rule.
NOTICE: declaration of 'i' line: 1 doesn't set type for the variable.
NOTICE: Declarations withouttype declaration found: 1
NOTICE: Declarations withouttype declaration found: 0
INFO: Checking fix type of the rule.
INFO: The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/vardeclared
import ../helpers.nim

const
  validOptions = @["type"]
  invalidOptions = @[]
  invalidNimCode = "var i = 1"
  validNimCode = "var i: int = 1"

runRuleTest(disabledChecks = {fixTests})
