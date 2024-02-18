include ../src/rules/ifstatements
import utils/helpers

const
  validOptions: seq[string] = @["all"]
  invalidOptions = @["randomoption", "anotheroption", "andmoreoption"]
  invalidNimCode = "if a != 1: echo \"not equal\" else: echo \"equal\""
  validNimCode = "if a == 1: echo \"equal\" else: echo \"not equal\""

runRuleTest(disabledChecks = {negativeFix, invalidSearch})
