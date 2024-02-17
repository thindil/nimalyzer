import ../src/rules/varuplevel
import utils/helpers

const
  validOptions = @[]
  invalidOptions = @["something"]
  invalidNimCode = """
var a: seq[int]
a.add(1)
let b: int = 3"""
  validNimCode = """
var a: seq[int]
a.add(1)
const b: int = 3"""

runRuleTest(moduleName = "varUplevel rule", disabledChecks = {invalidSearch, negativeFix})
