discard """
  exitcode: 0
"""

import std/logging
import ../../src/rules

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
addHandler(handler = logger)
setLogFilter(lvl = lvlInfo)

var resultValue: int = 0

message("Decrease value", resultValue)
assert resultValue == -1
message("Increase value", resultValue, lvlInfo, false)
assert resultValue == 0
