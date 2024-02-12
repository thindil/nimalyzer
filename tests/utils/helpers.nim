import std/logging
import compiler/[idents, options, parser]
import ../../src/rules
import unittest2

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

template runRuleTest*(moduleName: string; disabledChecks: set[DisabledChecks] = {}) =

  suite "Unit tests for " & moduleName & " module":

    checkpoint "Initializing the tests"
    setLogger()
    let
      (nimCache, nimConfig) = setNim()
    var
      validCode = parseString(validNimCode, nimCache, nimConfig)
      invalidCode = parseString(invalidNimCode, nimCache, nimConfig)
      ruleOptions = RuleOptions(parent: true, fileName: "tests/tcomments/test.nim",
          negation: false, ruleType: check, options: validOptions, amount: 0,
          enabled: true, maxResults: Natural.high)

    test "Checking the rule's options validation.":
      checkpoint "Validate invalid rule's options"
      check:
        not validateOptions(ruleSettings, invalidOptions)
      checkpoint "Validate valid rule's options"
      check:
        validateOptions(ruleSettings, validOptions)

    test "Checking check type of the rule":
      checkpoint "Checking the check type of the rule with the invalid code"
      ruleCheck(invalidCode, invalidCode, ruleOptions)
      check:
        ruleOptions.amount == 0
      checkpoint "Checking the check type of the rule with the valid code"
      ruleOptions.parent = true
      ruleCheck(validCode, validCode, ruleOptions)
      check:
        ruleOptions.amount > 0

    test "Checking negative check type of the rule":
      checkpoint "Checking the negative check type of the rule with the valid code"
      ruleOptions.parent = true
      ruleOptions.negation = true
      ruleOptions.amount = 0
      ruleCheck(validCode, validCode, ruleOptions)
      check:
        ruleOptions.amount == 0
      checkpoint "Checking the negative check type of the rule with the invalid code"
      ruleOptions.parent = true
      ruleCheck(invalidCode, invalidCode, ruleOptions)
      check:
        ruleOptions.amount > 0

    test "Checking search type of the rule":
      checkpoint "Checking search type of the rule with the invalid code."
      ruleOptions.parent = true
      ruleOptions.ruleType = search
      ruleOptions.negation = false
      ruleOptions.amount = 0
      ruleCheck(invalidCode, invalidCode, ruleOptions)
      if invalidSearch notin disabledChecks:
        check:
          ruleOptions.amount == 0
      checkpoint "Checking search type of the rule with the valid code."
      ruleOptions.parent = true
      ruleCheck(validCode, validCode, ruleOptions)
      check:
        ruleOptions.amount > 0

    test "Checking negative search type of the rule":
      checkpoint "Checking negative search type of the rule with the valid code."
      ruleOptions.parent = true
      ruleOptions.negation = true
      ruleOptions.amount = 0
      ruleCheck(validCode, validCode, ruleOptions)
      check:
        ruleOptions.amount == 0
      checkpoint "Checking negative search type of the rule with the invalid code."
      ruleOptions.parent = true
      ruleCheck(invalidCode, invalidCode, ruleOptions)
      check:
        ruleOptions.amount == 1

    test "Checking count type of the rule":
      checkpoint "Checking count type of the rule with the invalid code."
      ruleOptions.parent = true
      ruleOptions.ruleType = count
      ruleOptions.negation = false
      ruleOptions.amount = 0
      ruleCheck(invalidCode, invalidCode, ruleOptions)
      check:
        ruleOptions.amount == 1
      checkpoint "Checking count type of the rule with the valid code."
      ruleOptions.parent = true
      ruleOptions.amount = 0
      ruleCheck(validCode, validCode, ruleOptions)
      check:
        ruleOptions.amount == 1

    test "Checking negative count type of the rule":
      checkpoint "Checking negative count type of the rule with the invalid code."
      ruleOptions.parent = true
      ruleOptions.negation = true
      ruleOptions.amount = 0
      ruleCheck(invalidCode, invalidCode, ruleOptions)
      check:
        ruleOptions.amount == 1
      checkpoint "Checking negative count type of the rule with the valid code."
      ruleOptions.parent = true
      ruleOptions.amount = 0
      ruleCheck(validCode, validCode, ruleOptions)
      check:
        ruleOptions.amount == 1

    test "Checking fix type of the rule":
      checkpoint "Checking fix type of the rule."
      if fixTests notin disabledChecks:
        ruleOptions.parent = true
        ruleOptions.ruleType = fix
        ruleOptions.negation = false
        ruleOptions.amount = 0
        ruleOptions.identsCache = nimCache
        let oldInvalidCode = copyTree(invalidCode)
        ruleCheck(invalidCode, invalidCode, ruleOptions)
        check:
          $invalidCode == $validCode
        invalidCode = copyTree(oldInvalidCode)
#    # negative fix rule tests
#    info("Checking negative fix type of the rule.")
#    if negativeFix in disabledChecks:
#      info("The tests for negative fix type of rule are disabled.")
#    else:
#      ruleOptions.parent = true
#      ruleOptions.negation = true
#      ruleOptions.amount = 0
#      let oldValidCode = copyTree(validCode)
#      ruleCheck(validCode, validCode, ruleOptions)
#      try:
#        assert $invalidCode == $validCode
#      except AssertionDefect:
#        echo "Fixing the valid code with negation for rule '" &
#            ruleSettings.name & "' failed. Invalid code: " & $invalidCode &
#            "\nshould be: " & $validCode
#      validCode = copyTree(oldValidCode)
