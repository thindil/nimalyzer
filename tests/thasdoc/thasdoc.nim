discard """
  exitcode: 0
  outputsub: "randomoption"
"""

import std/logging
import ../../src/rules/hasdoc

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
addHandler(handler = logger)
setLogFilter(lvl = lvlInfo)

assert not validateOptions(@["randomoption"])
assert validateOptions(@[])
