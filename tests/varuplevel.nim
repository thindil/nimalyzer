include ../src/rules/varuplevel
import utils/helpers

const
  validOptions = @[]
  invalidOptions = @["something"]

runRuleTest(files = @["varuplevel"], disabledChecks = {invalidSearch, negativeFix})
