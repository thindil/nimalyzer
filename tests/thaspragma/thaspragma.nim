discard """
  exitcode: 0
  outputsub: "require type"
"""

import compiler/[idents, options, parser]
import ../../src/rules
import ../../src/rules/haspragma
import ../helpers.nim

const
  validOptions = @["procedures", "raises: [*"]
  invalidOptions = @[]
  invalidNimCode = "proc MyProc() = discard"
  validNimCode = "proc MyProc() {.raises: [].} = discard"

runRuleTest()
