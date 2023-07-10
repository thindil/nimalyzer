discard """
  exitcode: 0
  output: ''''''
"""

import ../../src/rules/forstatements
import ../helpers.nim

const
  validOptions: seq[string] = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "for i in [1 .. 6]: echo i"
  validNimCode = "for i in [1 .. 6].items: echo i"

runRuleTest()
