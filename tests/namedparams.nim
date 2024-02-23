include ../src/rules/namedparams
import utils/helpers

const
  validOptions = @[]
  invalidOptions = @["randomoption"]

runRuleTest(files = @["namedparams"], disabledChecks = {fixTests})
