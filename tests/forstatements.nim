include ../src/rules/forstatements
import utils/helpers

runRuleTest(files = @["forstatements"], validOptions = @["iterators"],
    invalidOptions = @["randomoption", "anotheroption"])
