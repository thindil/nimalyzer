include ../src/rules/haspragma
import utils/helpers

const
  validOptions = @["procedures", "raises: []"]
  invalidOptions = @[]

runRuleTest(files = @["haspragma"])
