include ../src/rules/assignments
import utils/helpers

runRuleTest(files = @["assignments"], validOptions = @["shorthand"],
    invalidOptions = @["randomoption", "anotheroption"])
