discard """
  exitcode: 0
  outputsub: "two options"
"""

import std/logging
import ../../src/rules/hasentity

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
addHandler(handler = logger)
setLogFilter(lvl = lvlInfo)

assert not validateOptions(@[""])
assert validateOptions(@["nkProcDef", "MyProc"])
