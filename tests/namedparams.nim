include ../src/rules/namedparams
import utils/helpers

const
  validOptions = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "quit(QuitSuccess)"
  validNimCode = "myProc(named = true)"

runRuleTest(disabledChecks = {fixTests})
