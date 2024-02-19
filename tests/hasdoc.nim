include ../src/rules/hasdoc
import utils/helpers

const
  validOptions: seq[string] = @["all", "tests/utils/doctemplate.txt"]
  invalidOptions = @["randomoption", "anotheroption", "thirdoption"]
  invalidNimCode = "var i* = 0"
  validNimCode = """## Template doc.
var i* = 0 ## Template doc."""

runRuleTest()
