include ../src/rules/hasdoc
import utils/helpers

const
  validOptions: seq[string] = @["all", "tests/utils/doctemplate.txt"]
  invalidOptions = @["randomoption", "anotheroption", "thirdoption"]

runRuleTest(files = @["hasdoc"])
