import std/logging
import compiler/[idents, options, parser]
import ../src/rules

proc setLogger*() =
  if getHandlers().len > 0:
    return
  let logger = newConsoleLogger()
  addHandler(handler = logger)
  setLogFilter(lvl = lvlInfo)

type DisabledChecks* = enum
  invalidSearch

template runRuleTest*(disabledChecks: set[DisabledChecks] = {}) =

  setLogger()

  assert not validateOptions(ruleSettings, invalidOptions)
  assert validateOptions(ruleSettings, validOptions)

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
  ruleCheck(invalidCode, invalidCode, ruleOptions)
  assert ruleOptions.amount == 0, "Check of invalid code for rule '" &
      ruleSettings.name & "' failed, expected result: 0, received: " &
      $ruleOptions.amount
  ruleOptions.parent = true
  ruleCheck(validCode, validCode, ruleOptions)
  assert ruleOptions.amount > 0, "Check of valid code for rule '" &
      ruleSettings.name &
      "' failed, expected result larger than 0, received: " &
      $ruleOptions.amount
  # negative check rule tests
  ruleOptions.parent = true
  ruleOptions.negation = true
  ruleOptions.amount = 0
  ruleCheck(validCode, validCode, ruleOptions)
  assert ruleOptions.amount == 0, "Negative check of valid code for rule '" &
      ruleSettings.name & "' failed, expected result: 0, received: " &
      $ruleOptions.amount
  ruleOptions.parent = true
  ruleCheck(invalidCode, invalidCode, ruleOptions)
  assert ruleOptions.amount > 0, "Negative check of invalid code for rule '" &
      ruleSettings.name &
      "' failed, expected result larger than 0, received: " &
      $ruleOptions.amount
  # search rule tests
  ruleOptions.parent = true
  ruleOptions.ruleType = search
  ruleOptions.negation = false
  ruleOptions.amount = 0
  ruleCheck(invalidCode, invalidCode, ruleOptions)
  if invalidSearch notin disabledChecks:
    assert ruleOptions.amount == 0, "Search for invalid code for rule '" &
        ruleSettings.name & "' failed, expected result: 0, received: " &
        $ruleOptions.amount
  else:
    echo "The test for searching for invalid code is disabled."
  ruleOptions.parent = true
  ruleCheck(validCode, validCode, ruleOptions)
  assert ruleOptions.amount > 0, "Search for valid code for rule '" &
      ruleSettings.name &
      "' failed, expected result greater than 0, received: " &
      $ruleOptions.amount
  # negative search rule tests
  ruleOptions.parent = true
  ruleOptions.negation = true
  ruleOptions.amount = 0
  ruleCheck(validCode, validCode, ruleOptions)
  assert ruleOptions.amount == 0, "Negative search for valid code for rule '" &
      ruleSettings.name & "' failed, expected result: 0, received: " &
      $ruleOptions.amount
  ruleOptions.parent = true
  ruleCheck(invalidCode, invalidCode, ruleOptions)
  assert ruleOptions.amount == 1, "Negative search for invalid code for rule '" &
      ruleSettings.name & "' failed, expected result: 1, received: " &
      $ruleOptions.amount
  # count rule tests
  ruleOptions.parent = true
  ruleOptions.ruleType = count
  ruleOptions.negation = false
  ruleOptions.amount = 0
  ruleCheck(invalidCode, invalidCode, ruleOptions)
  assert ruleOptions.amount == 1, "Counting of invalid code for rule '" &
      ruleSettings.name & "' failed, expected result: 1, received: " &
      $ruleOptions.amount
  ruleOptions.parent = true
  ruleOptions.amount = 0
  ruleCheck(validCode, validCode, ruleOptions)
  assert ruleOptions.amount == 1, "Counting of valid code for rule '" &
      ruleSettings.name & "' failed, expected result: 1, received: " &
      $ruleOptions.amount
  # negative count rule tests
  ruleOptions.parent = true
  ruleOptions.negation = true
  ruleOptions.amount = 0
  ruleCheck(invalidCode, invalidCode, ruleOptions)
  assert ruleOptions.amount == 1, "Negative counting of invalid code for rule '" &
      ruleSettings.name & "' failed, expected result: 1, received: " &
      $ruleOptions.amount
  ruleOptions.parent = true
  ruleOptions.amount = 0
  ruleCheck(validCode, validCode, ruleOptions)
  assert ruleOptions.amount == 1, "Negative counting of valid code for rule '" &
      ruleSettings.name & "' failed, expected result: 1, received: " &
      $ruleOptions.amount
