discard """
  exitcode: 0
  outputsub: "two options"
"""

import std/logging
import compiler/[idents, options, parser]
import ../../src/rules/hasentity
import ../../src/rules

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
addHandler(handler = logger)
setLogFilter(lvl = lvlInfo)

assert not validateOptions(@[])
assert validateOptions(@["nkProcDef", "MyProc"])

let
  nimCache = newIdentCache()
  nimConfig = newConfigRef()
nimConfig.options.excl(y = optHints)
let
  invalidCode = parseString("quit", nimCache, nimConfig)
  validCode = parseString("proc MyProc() = discard", nimCache, nimConfig)
var ruleOptions = RuleOptions(parent: true, fileName: "test.nim", negation: false,
      ruleType: check, options: @["nkProcDef", "MyProc"], amount: 0)

# check rule tests
assert ruleCheck(invalidCode, ruleOptions) == 0
assert ruleCheck(validCode, ruleOptions) == 1
# negative check rule tests
ruleOptions.negation = true
assert ruleCheck(invalidCode, ruleOptions) == 1
assert ruleCheck(validCode, ruleOptions) == 0
# search rule tests
ruleOptions.ruleType = search
ruleOptions.negation = false
assert ruleCheck(invalidCode, ruleOptions) == 0
assert ruleCheck(validCode, ruleOptions) == 1
# negative search rule tests
ruleOptions.negation = true
assert ruleCheck(invalidCode, ruleOptions) == 1
assert ruleCheck(validCode, ruleOptions) == 0
# count rule tests
ruleOptions.ruleType = count
ruleOptions.negation = false
assert ruleCheck(invalidCode, ruleOptions) == 1
assert ruleCheck(validCode, ruleOptions) == 1
# negative count rule tests
ruleOptions.negation = true
assert ruleCheck(invalidCode, ruleOptions) == 1
assert ruleCheck(validCode, ruleOptions) == 1
