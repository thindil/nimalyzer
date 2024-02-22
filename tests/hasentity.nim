include ../src/rules/hasentity
import utils/helpers

const
  validOptions = @["nkProcDef", "MyProc"]
  invalidOptions = @[""]

runRuleTest(files = @["hasentity"], disabledChecks = {fixTests})
