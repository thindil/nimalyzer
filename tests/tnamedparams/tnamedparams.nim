discard """
  exitcode: 0
  outputsub: "randomoption"
"""

import compiler/[idents, options, parser]
import ../../src/rules
import ../../src/rules/namedparams
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "quit(QuitSuccess)"
  validNimCode = "myProc(named = true)"

runRuleTest()
