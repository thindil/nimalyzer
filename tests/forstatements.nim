include ../src/rules/forstatements
import utils/helpers

const
  validOptions: seq[string] = @["iterators"]
  invalidOptions = @["randomoption", "anotheroption"]

runRuleTest(files = @["forstatements"])
