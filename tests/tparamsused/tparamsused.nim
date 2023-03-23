discard """
  exitcode: 0
  outputsub: "randomoption"
"""

import ../../src/rules/paramsused
import ../helpers.nim

const
  validOptions = @["procedures"]
  invalidOptions = @["randomoption"]
  invalidNimCode = "proc MyProc(arg: int) = discard"
  validNimCode = "proc MyProc(arg: int) = echo $arg"

runRuleTest()
