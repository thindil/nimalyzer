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
let
  invalidCode = parseString("quit", nimCache, nimConfig)
  validCode = parseString("## Doc", nimCache, nimConfig)
var ruleOptions = RuleOptions(parent: true, fileName: "test.nim", negation: false,
      ruleType: check, options: @[], amount: 0)

# check rule tests
assert ruleCheck(invalidCode, ruleOptions) == 0
assert ruleCheck(validCode, ruleOptions) == 1
# negative check rule tests
ruleOptions.negation = true
assert ruleCheck(invalidCode, ruleOptions) == 1
