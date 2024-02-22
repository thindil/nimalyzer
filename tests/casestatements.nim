include ../src/rules/casestatements
import utils/helpers

const
  validOptions: seq[string] = @["min", "2"]
  invalidOptions = @["randomoption", "anotheroption", "andmoreoption"]

runRuleTest(files = @["casestatements"], disabledChecks = {invalidSearch, fixTests})
