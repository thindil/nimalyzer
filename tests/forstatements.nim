import ../src/rules/forstatements
import utils/helpers

const
  validOptions: seq[string] = @["iterators"]
  invalidOptions = @["randomoption", "anotheroption"]
  invalidNimCode = "for i in [1 .. 6]: echo i"
  validNimCode = "for i in [1 .. 6].items: echo i"

runRuleTest(moduleName = "forstatements rule")
