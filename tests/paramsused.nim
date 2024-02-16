import ../src/rules/paramsused
import utils/helpers

const
  validOptions = @["procedures"]
  invalidOptions = @["randomoption"]
  invalidNimCode = "proc MyProc(arg: int) = discard"
  validNimCode = "proc MyProc(arg: int) = echo $arg"

runRuleTest(moduleName = "paramsUsed rule", disabledChecks = {fixTests})
