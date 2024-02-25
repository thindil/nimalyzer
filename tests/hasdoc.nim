include ../src/rules/hasdoc
import utils/helpers

runRuleTest(files = @["hasdoc"], validOptions = @["all",
    "tests/utils/doctemplate.txt"], invalidOptions = @["randomoption",
    "anotheroption", "thirdoption"])
