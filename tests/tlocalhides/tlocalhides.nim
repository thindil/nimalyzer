discard """
  exitcode: 0
  output: '''FATAL The rule localhides requires at maximum 0 options, but 1 provided: 'randomoption'.
ERROR declaration of 'a' line: 1 is hidden by local variable in line 3.
ERROR declaration of 'a' line: 3 is hidden by local variable in line 5.
ERROR declaration of 'a' line: 1 is not hidden by local variable.
ERROR declaration of 'locala' line: 3 is not hidden by local variable.
ERROR declaration of 'locallocala' line: 5 is not hidden by local variable.
ERROR declaration of 'a' line: 5 is not hidden by local variable.
NOTICE declaration of 'a' line: 5 is not hidden by local variable.
The test for searching for invalid code is disabled.
NOTICE declaration of 'a' line: 1 is not hidden by local variable.
NOTICE declaration of 'locala' line: 3 is not hidden by local variable.
NOTICE declaration of 'locallocala' line: 5 is not hidden by local variable.
NOTICE Local declarations which hide global declarations not found.
NOTICE declaration of 'a' line: 1 is hidden by local variable in line 3.
NOTICE declaration of 'a' line: 3 is hidden by local variable in line 5.
NOTICE Local declarations which hide global declarations found: 1
NOTICE Local declarations which hide global declarations found: 3
NOTICE declaration of 'a' line: 1 is hidden by local variable in line 3.
NOTICE declaration of 'a' line: 3 is hidden by local variable in line 5.
NOTICE Local declarations which hide global declarations found: 1
NOTICE Local declarations which hide global declarations found: 0
ERROR declaration of 'a' line: 1 is hidden by local variable in line 3.
ERROR declaration of 'locala' line: 3 is hidden by local variable in line 5.
The tests for negative fix type of rule are disabled.'''
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
