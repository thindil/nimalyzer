discard """
  exitcode: 0
"""

import ../../src/[config, main]
import ../helpers

setLogger()

var sections = 0
let (sources, rules, fixCommand, maxReports) = parseConfig(
    "config/nimalyzer.cfg", sections)
assert sources.len > 0 and rules.len > 0 and fixCommand.len > 0 and sections ==
    1 and maxReports == Natural.high, "Failed to parse the config file."
