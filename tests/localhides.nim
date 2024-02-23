include ../src/rules/localhides
import utils/helpers

const
  validOptions: seq[string] = @[]
  invalidOptions = @["randomoption"]

# Disable check for invalid code search as it always returns error instead of
# positive value. Also, disable check for negative fix type of rule as it
# do nothing.
runRuleTest(files = @["localhides"], disabledChecks = {invalidSearch, negativeFix})
