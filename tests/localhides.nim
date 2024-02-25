include ../src/rules/localhides
import utils/helpers

# Disable check for invalid code search as it always returns error instead of
# positive value. Also, disable check for negative fix type of rule as it
# do nothing.
runRuleTest(files = @["localhides"], validOptions = @[], invalidOptions = @[
    "randomoption"], disabledChecks = {invalidSearch, negativeFix})
