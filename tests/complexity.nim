include ../src/rules/complexity
import utils/helpers

const
  validOptions: seq[string] = @["cyclomatic", "all", "2"]
  invalidOptions = @["randomoption", "anotheroption"]

runRuleTest(files = @["complexity"], disabledChecks = {fixTests})
