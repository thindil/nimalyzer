discard """
  exitcode: 0
  outputsub: "require name"
"""

import std/logging
import compiler/[idents, options, parser]
import ../../src/rules
import ../../src/rules/haspragma

let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
addHandler(handler = logger)
setLogFilter(lvl = lvlInfo)

assert not validateOptions(@[])
assert validateOptions(@["raises: [*"])

let
  nimCache = newIdentCache()
  nimConfig = newConfigRef()
nimConfig.options.excl(y = optHints)
var
  code = parseString("quit", nimCache, nimConfig)
  ruleOptions = RuleOptions(parent: true, fileName: "test.nim", negation: false,
      ruleType: check, options: @["raises: [*"], amount: 0)
assert ruleCheck(code, ruleOptions) == 0
code = parseString("proc MyProc() {.raises: [].} = discard", nimCache, nimConfig)
assert ruleCheck(code, ruleOptions) == 1
