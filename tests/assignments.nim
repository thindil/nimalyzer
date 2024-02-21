include ../src/rules/assignments
import utils/helpers

const
  validOptions: seq[string] = @["shorthand"]
  invalidOptions = @["randomoption", "anotheroption"]

runRuleTest(files = @["assignments"])
