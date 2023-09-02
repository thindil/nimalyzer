discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule localhides requires at maximum 0 options, but 1 provided: 'randomoption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: rule: localhides, declaration of 'a' line: 1 is hidden by local variable in line 3.
ERROR: rule: localhides, declaration of 'a' line: 3 is hidden by local variable in line 5.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: rule: localhides, declaration of 'a' line: 1 is not hidden by local variable.
ERROR: rule: localhides, declaration of 'locala' line: 3 is not hidden by local variable.
ERROR: rule: localhides, declaration of 'locallocala' line: 5 is not hidden by local variable.
INFO: Checking negative check type of the rule with the invalid code.
ERROR: rule: localhides, declaration of 'a' line: 5 is not hidden by local variable.
INFO: Checking search type of the rule with the invalid code.
NOTICE: rule: localhides, declaration of 'a' line: 5 is not hidden by local variable.
INFO: The test for searching for invalid code is disabled.
INFO: Checking search type of the rule with the valid code.
NOTICE: rule: localhides, declaration of 'a' line: 1 is not hidden by local variable.
NOTICE: rule: localhides, declaration of 'locala' line: 3 is not hidden by local variable.
NOTICE: rule: localhides, declaration of 'locallocala' line: 5 is not hidden by local variable.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: rule: localhides, Local declarations which hide global declarations not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: rule: localhides, declaration of 'a' line: 1 is hidden by local variable in line 3.
NOTICE: rule: localhides, declaration of 'a' line: 3 is hidden by local variable in line 5.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Local declarations which hide global declarations found: 1
INFO: Checking count type of the rule with the valid code.
NOTICE: Local declarations which hide global declarations found: 3
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: rule: localhides, declaration of 'a' line: 1 is hidden by local variable in line 3.
NOTICE: rule: localhides, declaration of 'a' line: 3 is hidden by local variable in line 5.
NOTICE: Local declarations which hide global declarations found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Local declarations which hide global declarations found: 0
INFO: Checking fix type of the rule.
ERROR: rule: localhides, declaration of 'a' line: 1 is hidden by local variable in line 3.
ERROR: rule: localhides, declaration of 'locala' line: 3 is hidden by local variable in line 5.
INFO: Checking negative fix type of the rule.
INFO: The tests for negative fix type of rule are disabled.'''
"""

import ../../src/rules/localhides
import ../helpers.nim

const
  validOptions: seq[string] = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = """
var a = 1
for i in 1 .. 10:
  var a = 2
  for j in 2 .. 3:
    var a = 3"""
  validNimCode = """
var a = 1
for i in 1 .. 10:
  var locala = 2
  for j in 2 .. 3:
    var locallocala = 3"""

# Disable check for invalid code search as it always returns error instead of
# positive value. Also, disable check for negative fix type of rule as it
# do nothing.
runRuleTest(disabledChecks = {invalidSearch, negativeFix})
