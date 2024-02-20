include ../src/rules/localhides
import utils/helpers

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
