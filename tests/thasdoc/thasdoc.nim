discard """
  exitcode: 0
  outputsub: "randomoption"
"""

import std/logging
import compiler/[idents, options, parser]
import ../../src/rules/hasdoc
import ../../src/rules

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
addHandler(handler = logger)
setLogFilter(lvl = lvlInfo)

assert not validateOptions(@["randomoption"])
assert validateOptions(@[])

let
  nimCache = newIdentCache()
  nimConfig = newConfigRef()
nimConfig.options.excl(y = optHints)
var
  code = parseString("quit", nimCache, nimConfig)
  ruleOptions = RuleOptions(parent: true, fileName: "test.nim", negation: false,
      ruleType: check, options: @[], amount: 0)
assert ruleCheck(code, ruleOptions) == -1
code = parseString("## Doc", nimCache, nimConfig)
assert ruleCheck(code, ruleOptions) == 1
