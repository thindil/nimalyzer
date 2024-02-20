include ../src/rules/haspragma
import utils/helpers

const
  validOptions = @["procedures", "raises: []"]
  invalidOptions = @[]
  invalidNimCode = "proc MyProc() = discard"
  validNimCode = "proc MyProc() {.raises: [].} = discard"

runRuleTest()
