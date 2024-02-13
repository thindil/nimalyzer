import ../src/rules/casestatements
import utils/helpers

const
  validOptions: seq[string] = @["min", "2"]
  invalidOptions = @["randomoption", "anotheroption", "andmoreoption"]
  invalidNimCode = """case a
  of 1:
    echo a"""
  validNimCode = """case a
  of 1:
    echo a
  of 2:
    echo a"""

runRuleTest(moduleName = "casestatements", disabledChecks = {invalidSearch, fixTests})
