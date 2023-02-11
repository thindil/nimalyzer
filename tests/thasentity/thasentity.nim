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
var
  code = parseString("quit", nimCache, nimConfig)
  ruleOptions = RuleOptions(parent: true, fileName: "test.nim", negation: false,
      ruleType: check, options: @["nkProcDef", "MyProc"], amount: 0)
assert ruleCheck(code, ruleOptions) == -1
code = parseString("proc MyProc() = discard", nimCache, nimConfig)
assert ruleCheck(code, ruleOptions) == 1
