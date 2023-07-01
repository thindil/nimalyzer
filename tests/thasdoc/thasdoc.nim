discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule hasdoc requires at maximum 2 options, but 3 provided: 'randomoption, anotheroption, thirdoption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: Module doesn't have documentation.
ERROR: Declaration of i* at 1 doesn't have documentation.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: Module has documentation.
ERROR: Declaration of i* at 2 has documentation.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: The documentation not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: Module has documentation.
NOTICE: Declaration of i* at 2 has documentation.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: The documentation not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: Module doesn't have documentation.
NOTICE: Declaration of i* at 1 doesn't have documentation.
Negative search for invalid code for rule 'hasdoc' failed, expected result: 1, received: 2
INFO: Checking count type of the rule with the invalid code.
NOTICE: Declared public items with documentation found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Declared public items with documentation found: 2
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: Module doesn't have documentation.
NOTICE: Declaration of i* at 1 doesn't have documentation.
NOTICE: Declared public items with documentation found: 2
INFO: Checking negative count type of the rule with the valid code.
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
