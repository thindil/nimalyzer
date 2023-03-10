import std/logging

proc setLogger*() =
  if getHandlers().len > 0:
    return
  let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
  addHandler(handler = logger)
  setLogFilter(lvl = lvlInfo)

template runRuleTest*() =

  setLogger()

  assert not validateOptions(invalidOptions)
  assert validateOptions(validOptions)

  let
    nimCache = newIdentCache()
    nimConfig = newConfigRef()
  nimConfig.options.excl(y = optHints)
  let
    invalidCode = parseString(invalidNimCode, nimCache, nimConfig)
    validCode = parseString(validNimCode, nimCache, nimConfig)
  var ruleOptions = RuleOptions(parent: true, fileName: "test.nim", negation: false,
        ruleType: check, options: validOptions, amount: 0, enabled: true)

  # check rule tests
  ruleCheck(invalidCode, ruleOptions)
  assert ruleOptions.amount == 0
  ruleOptions.parent = true
  ruleCheck(validCode, ruleOptions)
  assert ruleOptions.amount == 1
  # negative check rule tests
  ruleOptions.parent = true
  ruleOptions.negation = true
  ruleOptions.amount = 0
  ruleCheck(validCode, ruleOptions)
  assert ruleOptions.amount == 0
  ruleOptions.parent = true
  ruleCheck(invalidCode, ruleOptions)
  assert ruleOptions.amount == 1
  # search rule tests
  ruleOptions.parent = true
  ruleOptions.ruleType = search
  ruleOptions.negation = false
  ruleOptions.amount = 0
  ruleCheck(invalidCode, ruleOptions)
  assert ruleOptions.amount == 0
  ruleOptions.parent = true
  ruleCheck(validCode, ruleOptions)
  assert ruleOptions.amount == 1
  # negative search rule tests
  ruleOptions.parent = true
  ruleOptions.negation = true
  ruleOptions.amount = 0
  ruleCheck(validCode, ruleOptions)
  assert ruleOptions.amount == 0
  ruleOptions.parent = true
  ruleCheck(invalidCode, ruleOptions)
  assert ruleOptions.amount == 1
  # count rule tests
  ruleOptions.parent = true
  ruleOptions.ruleType = count
  ruleOptions.negation = false
  ruleOptions.amount = 0
  ruleCheck(invalidCode, ruleOptions)
  assert ruleOptions.amount == 1
  ruleOptions.parent = true
  ruleOptions.amount = 0
  ruleCheck(validCode, ruleOptions)
  assert ruleOptions.amount == 1
  # negative count rule tests
  ruleOptions.parent = true
  ruleOptions.negation = true
  ruleOptions.amount = 0
  ruleCheck(invalidCode, ruleOptions)
  assert ruleOptions.amount == 1
  ruleOptions.parent = true
  ruleOptions.amount = 0
  ruleCheck(validCode, ruleOptions)
  assert ruleOptions.amount == 1
