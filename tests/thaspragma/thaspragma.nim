discard """
  exitcode: 0
  outputsub: "require name"
"""

import compiler/[idents, options, parser]
import ../../src/rules
import ../../src/rules/haspragma
import ../helpers.nim

const
  validOptions = @["raises: [*"]
  invalidOptions = @[]
  invalidNimCode = "proc MyProc() = discard"
  validNimCode = "proc MyProc() {.raises: [].} = discard"

runRuleTest()
