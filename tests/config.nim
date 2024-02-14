{.warning[UnusedImport]:off.}
import ../src/[config, main]
import utils/helpers
import unittest2

suite "Unit tests for config module":

  setLogger()

  test "Test parsing configuration file":
    var sections = 0
    let (sources, rules, fixCommand, maxReports) = parseConfig(
        "config/nimalyzer.cfg", sections)
    check:
      sources.len > 0 and rules.len > 0 and fixCommand.len > 0 and sections ==
        1 and maxReports == Natural.high
