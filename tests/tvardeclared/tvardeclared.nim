discard """
  exitcode: 0
  outputsub: "require type"
"""

import ../../src/rules/vardeclared
import ../helpers.nim

const
  validOptions = @["type"]
  invalidOptions = @[]
  invalidNimCode = "var i = 1"
  validNimCode = "var i: int = 1"

runRuleTest()
