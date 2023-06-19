discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule hasdoc requires at maximum 2 options, but 3 provided: 'randomoption, anotheroption, thirdoption'.
INFO: Checking check type of the rule.
ERROR: Module doesn't have documentation.
INFO: Checking negative check type of the rule.
ERROR: Module has documentation.
INFO: Checking search type of the rule.
NOTICE: The documentation not found.
NOTICE: Module has documentation.
INFO: Checking negative search type of the rule.
NOTICE: The documentation not found.
NOTICE: Module doesn't have documentation.
INFO: Checking count type of the rule.
NOTICE: Declared public items with documentation found: 0
NOTICE: Declared public items with documentation found: 1
INFO: Checking negative type of the rule.
NOTICE: Module doesn't have documentation.
NOTICE: Declared public items with documentation found: 1
NOTICE: Declared public items with documentation found: 0
INFO: Checking fix type of the rule.
INFO: The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/hasdoc
import ../helpers.nim

const
  validOptions: seq[string] = @["all"]
  invalidOptions = @["randomoption", "anotheroption", "thirdoption"]
  invalidNimCode = "quit"
  validNimCode = "## Doc"

runRuleTest(disabledChecks = {fixTests})
