import ../src/rules/hasentity
import utils/helpers

const
  validOptions = @["nkProcDef", "MyProc"]
  invalidOptions = @[""]
  invalidNimCode = "quit"
  validNimCode = "proc MyProc() = discard"

runRuleTest(moduleName = "hasEntity rule", disabledChecks = {fixTests})
