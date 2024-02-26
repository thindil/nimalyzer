include ../src/rules/vardeclared
import utils/helpers

runRuleTest(files = @["vardeclared"], validOptions = @["type"],
    invalidOptions = @[], disabledChecks = {fixTests})
