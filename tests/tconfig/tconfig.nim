discard """
  exitcode: 0
"""

import ../../src/config
import ../helpers

setLogger()

let (sources, rules) = parseConfig("config/nimalyzer.cfg")
assert sources.len > 0 and rules.len > 0
