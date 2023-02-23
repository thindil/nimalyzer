discard """
  exitcode: 0
  outputsub: "two or three options"
"""

import compiler/[idents, options, parser]
import ../../src/rules/hasentity
import ../../src/rules
import ../helpers.nim

const
  validOptions = @["nkProcDef", "MyProc"]
  invalidOptions = @[""]
  invalidNimCode = "quit"
  validNimCode = "proc MyProc() = discard"

runRuleTest()
