include ../src/rules/hasentity
import utils/helpers

runRuleTest(files = @["hasentity"], validOptions = @["nkProcDef", "MyProc"],
    invalidOptions = @[""], disabledChecks = {fixTests})
