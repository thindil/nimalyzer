include ../src/rules/namingconv
import utils/helpers

const
  validOptions = @["variables", "[a-z][a-zA-Z0-9_]"]
  invalidOptions = @[]
  invalidNimCode = "var IsThe: int = 1"
  validNimCode = "var isThe: int = 1"

runRuleTest(disabledChecks = {fixTests})
