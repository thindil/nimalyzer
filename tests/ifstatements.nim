include ../src/rules/ifstatements
import utils/helpers

runRuleTest(files = @["ifstatements"], validOptions = @["all"],
    invalidOptions = @["randomoption", "anotheroption", "andmoreoption"],
    disabledChecks = {negativeFix, invalidSearch})
