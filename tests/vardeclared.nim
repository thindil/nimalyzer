include ../src/rules/vardeclared
import utils/helpers

const
  validOptions = @["type"]
  invalidOptions = @[]

runRuleTest(files = @["vardeclared"], disabledChecks = {fixTests})
