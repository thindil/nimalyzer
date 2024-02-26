include ../src/rules/varuplevel
import utils/helpers

runRuleTest(files = @["varuplevel"], validOptions = @[], invalidOptions = @[
    "something"], disabledChecks = {invalidSearch, negativeFix})
