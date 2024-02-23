include ../src/rules/paramsused
import utils/helpers

const
  validOptions = @["procedures"]
  invalidOptions = @["randomoption"]

runRuleTest(files = @["paramsused"], disabledChecks = {fixTests})
