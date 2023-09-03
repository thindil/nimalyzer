discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule vardeclared requires at least 1 options, but only 0 provided: ''.
INFO: Checking check type of the rule with the invalid code.
ERROR: rule: vardeclared, declaration of 'i' line: 1 doesn't set type for the variable.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: rule: vardeclared, declaration of i line: 1 sets the type 'int' as the type of the variable.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: rule: vardeclared, Declarations withtype declaration not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: rule: vardeclared, declaration of i line: 1 sets the type 'int' as the type of the variable.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: rule: vardeclared, Declarations withouttype declaration not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: rule: vardeclared, declaration of 'i' line: 1 doesn't set type for the variable.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Declarations withtype declaration found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Declarations withtype declaration found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: rule: vardeclared, declaration of 'i' line: 1 doesn't set type for the variable.
NOTICE: Declarations withouttype declaration found: 1
INFO: Checking negative count type of the rule with the valid code.
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
