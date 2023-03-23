discard """
  exitcode: 0
  outputsub: "randomoption"
"""

import compiler/[idents, options, parser]
import ../../src/rules/hasdoc
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "quit"
  validNimCode = "## Doc"

runRuleTest()
