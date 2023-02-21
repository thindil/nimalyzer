discard """
  exitcode: 0
  outputsub: "randomoption"
"""

import compiler/[idents, options, parser]
import ../../src/rules
import ../../src/rules/paramsused
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "proc MyProc(arg: int) = discard"
  validNimCode = "proc MyProc(arg: int) = echo $arg"

runRuleTest()
