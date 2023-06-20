discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule hasdoc requires at maximum 2 options, but 3 provided: 'randomoption, anotheroption, thirdoption'.
INFO: Checking check type of the rule.
ERROR: Module doesn't have documentation.
ERROR: Declaration of i* at 1 doesn't have documentation.
INFO: Checking negative check type of the rule.
ERROR: Module has documentation.
ERROR: Declaration of i* at 2 has documentation.
INFO: Checking search type of the rule.
NOTICE: The documentation not found.
NOTICE: Module has documentation.
NOTICE: Declaration of i* at 2 has documentation.
INFO: Checking negative search type of the rule.
NOTICE: The documentation not found.
NOTICE: Module doesn't have documentation.
NOTICE: Declaration of i* at 1 doesn't have documentation.
Negative search for invalid code for rule 'hasdoc' failed, expected result: 1, received: 2
INFO: Checking count type of the rule.
NOTICE: Declared public items with documentation found: 0
NOTICE: Declared public items with documentation found: 2
INFO: Checking negative type of the rule.
NOTICE: Module doesn't have documentation.
NOTICE: Declaration of i* at 1 doesn't have documentation.
NOTICE: Declared public items with documentation found: 2
NOTICE: Declared public items with documentation found: 0
INFO: Checking fix type of the rule.
ERROR: Module doesn't have documentation.
ERROR: Declaration of i* at 1 doesn't have documentation.
INFO: Checking negative fix type of the rule.
ERROR: Module has documentation.
ERROR: Declaration of i* at 2 has documentation.'''
"""

import ../../src/rules/hasdoc
import ../helpers.nim

const
  validOptions: seq[string] = @["all", "tests/thasdoc/doctemplate.txt"]
  invalidOptions = @["randomoption", "anotheroption", "thirdoption"]
  invalidNimCode = "var i* = 0"
  validNimCode = """## Template doc.
var i* = 0 ## Template doc."""

runRuleTest()
