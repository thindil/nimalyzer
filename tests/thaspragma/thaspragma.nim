discard """
  exitcode: 0
  outputsub: "require name"
"""

import std/logging
import ../../src/rules/haspragma

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
addHandler(handler = logger)
setLogFilter(lvl = lvlInfo)

assert not validateOptions(@[])
assert validateOptions(@["raises: [*"])
