include ../src/rules/assignments
import utils/helpers

const
  validOptions: seq[string] = @["shorthand"]
  invalidOptions = @["randomoption", "anotheroption"]
  invalidNimCode = """var i = 1
i = i + 1"""
  validNimCode = """var i = 1
i += 1"""

runRuleTest()
