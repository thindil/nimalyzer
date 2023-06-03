discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule localhides requires at maximum 0 options, but 1 provided: 'randomoption'.
INFO: Checking check type of the rule.
ERROR: declaration of 'a' line: 1 is hidden by local variable in line 3.
ERROR: declaration of 'a' line: 3 is hidden by local variable in line 5.
INFO: Checking negative check type of the rule.
ERROR: declaration of 'a' line: 1 is not hidden by local variable.
ERROR: declaration of 'locala' line: 3 is not hidden by local variable.
ERROR: declaration of 'locallocala' line: 5 is not hidden by local variable.
ERROR: declaration of 'a' line: 5 is not hidden by local variable.
INFO: Checking search type of the rule.
NOTICE: declaration of 'a' line: 5 is not hidden by local variable.
INFO: The test for searching for invalid code is disabled.
NOTICE: declaration of 'a' line: 1 is not hidden by local variable.
NOTICE: declaration of 'locala' line: 3 is not hidden by local variable.
NOTICE: declaration of 'locallocala' line: 5 is not hidden by local variable.
INFO: Checking negative search type of the rule.
NOTICE: Local declarations which hide global declarations not found.
NOTICE: declaration of 'a' line: 1 is hidden by local variable in line 3.
NOTICE: declaration of 'a' line: 3 is hidden by local variable in line 5.
INFO: Checking count type of the rule.
NOTICE: Local declarations which hide global declarations found: 1
NOTICE: Local declarations which hide global declarations found: 3
INFO: Checking negative type of the rule.
NOTICE: declaration of 'a' line: 1 is hidden by local variable in line 3.
NOTICE: declaration of 'a' line: 3 is hidden by local variable in line 5.
NOTICE: Local declarations which hide global declarations found: 1
NOTICE: Local declarations which hide global declarations found: 0
INFO: Checking fix type of the rule.
ERROR: declaration of 'a' line: 1 is hidden by local variable in line 3.
ERROR: declaration of 'locala' line: 3 is hidden by local variable in line 5.
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
