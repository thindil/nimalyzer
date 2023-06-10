discard """
  exitcode: 0
"""

import ../../src/config
import ../helpers

setLogger()

var sections = 0
let (sources, rules, fixCommand) = parseConfig("config/nimalyzer.cfg", sections)
assert sources.len > 0 and rules.len > 0 and fixCommand.len > 0 and sections == 1
