import std/logging
import compiler/[idents, options, parser]
import ../src/rules

type DisabledChecks* = enum
  invalidSearch, fixTests, negativeFix

proc setLogger*() =
  if getHandlers().len > 0:
    return
  let logger = newConsoleLogger(fmtStr = "$levelname: ")
  addHandler(handler = logger)
  setLogFilter(lvl = lvlInfo)

proc setNim*(): tuple[cache: IdentCache, config: ConfigRef] =
  let
    nimCache = newIdentCache()
    nimConfig = newConfigRef()
  nimConfig.options.excl(y = optHints)
  return (nimCache, nimConfig)

template runRuleTest*(disabledChecks: set[DisabledChecks] = {}) =

  setLogger()

  info("Checking the rule's options validation.")
  assert not validateOptions(ruleSettings, invalidOptions)
  assert validateOptions(ruleSettings, validOptions)

  let
    (nimCache, nimConfig) = setNim()
  var
    validCode = parseString(validNimCode, nimCache, nimConfig)
    invalidCode = parseString(invalidNimCode, nimCache, nimConfig)
    ruleOptions = RuleOptions(parent: true, fileName: "test.nim",
        negation: false, ruleType: check, options: validOptions, amount: 0, enabled: true)

  # check rule tests
  info("Checking check type of the rule.")
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
  info("Checking negative check type of the rule.")
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
  info("Checking search type of the rule.")
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
    info("The test for searching for invalid code is disabled.")
  ruleOptions.parent = true
  ruleCheck(validCode, validCode, ruleOptions)
  assert ruleOptions.amount > 0, "Search for valid code for rule '" &
      ruleSettings.name &
      "' failed, expected result greater than 0, received: " &
      $ruleOptions.amount
  # negative search rule tests
  info("Checking negative search type of the rule.")
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
  info("Checking count type of the rule.")
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
  info("Checking negative type of the rule.")
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
  # fix rule tests
  info("Checking fix type of the rule.")
  if fixTests in disabledChecks:
    info("The tests for fix type of rule are disabled.")
  else:
    ruleOptions.parent = true
    ruleOptions.ruleType = fix
    ruleOptions.negation = false
    ruleOptions.amount = 0
    ruleOptions.identsCache = nimCache
    let oldInvalidCode = copyTree(invalidCode)
    ruleCheck(invalidCode, invalidCode, ruleOptions)
    assert $invalidCode == $validCode, "Fixing the invalid code for rule '" &
        ruleSettings.name & "' failed. Invalid code: " & $invalidCode &
        "\nshould be: " & $validCode
    invalidCode = copyTree(oldInvalidCode)
    # negative fix rule tests
    info("Checking negative fix type of the rule.")
    if negativeFix in disabledChecks:
      info("The tests for negative fix type of rule are disabled.")
    else:
      ruleOptions.parent = true
      ruleOptions.negation = true
      ruleOptions.amount = 0
      let oldValidCode = copyTree(validCode)
      ruleCheck(validCode, validCode, ruleOptions)
      assert $invalidCode == $validCode,
          "Fixing the valid code with negation for rule '" & ruleSettings.name &
              "' failed. Invalid code: " & $invalidCode & "\nshould be: " & $validCode
      validCode = copyTree(oldValidCode)
