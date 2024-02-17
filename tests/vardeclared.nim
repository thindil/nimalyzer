import ../src/rules/vardeclared
import utils/helpers

const
  validOptions = @["type"]
  invalidOptions = @[]
  invalidNimCode = "var i = 1"
  validNimCode = "var i: int = 1"

runRuleTest(moduleName = "varDeclared rule", disabledChecks = {fixTests})
