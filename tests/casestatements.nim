include ../src/rules/casestatements
import utils/helpers

runRuleTest(files = @["casestatements"], validOptions = @["min", "2"],
    invalidOptions = @["randomoption", "anotheroption", "andmoreoption"],
    disabledChecks = {invalidSearch, fixTests})
