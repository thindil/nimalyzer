include ../src/rules/namedparams
import utils/helpers

runRuleTest(files = @["namedparams"], validOptions = @[], invalidOptions = @[
    "randomoption"], disabledChecks = {fixTests})
