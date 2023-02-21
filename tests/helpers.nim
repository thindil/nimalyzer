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
        ruleType: check, options: validOptions, amount: 0)

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
