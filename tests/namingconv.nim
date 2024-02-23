include ../src/rules/namingconv
import utils/helpers

const
  validOptions = @["variables", "[a-z][a-zA-Z0-9_]"]
  invalidOptions = @[]

runRuleTest(files = @["namingconv"], disabledChecks = {fixTests})
