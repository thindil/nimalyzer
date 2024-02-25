include ../src/rules/haspragma
import utils/helpers

runRuleTest(files = @["haspragma"], validOptions = @["procedures",
    "raises: []"], invalidOptions = @[])
