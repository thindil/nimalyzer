include ../src/rules/ifstatements
import utils/helpers

const
  validOptions: seq[string] = @["all"]
  invalidOptions = @["randomoption", "anotheroption", "andmoreoption"]

runRuleTest(files = @["ifstatements"], disabledChecks = {negativeFix,
    invalidSearch})
