import ../src/rules/complexity
import utils/helpers

const
  validOptions: seq[string] = @["cyclomatic", "all", "2"]
  invalidOptions = @["randomoption", "anotheroption"]
  invalidNimCode = """if i == 1 and b == 2:
  i = i + 1"""
  validNimCode = """if i == 1:
  i += 1"""

runRuleTest(moduleName = "complexity rule", disabledChecks = {fixTests})
