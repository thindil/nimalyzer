include ../src/rules/paramsused
import utils/helpers

runRuleTest(files = @["paramsused"], validOptions = @["procedures"],
    invalidOptions = @["randomoption"], disabledChecks = {fixTests})
