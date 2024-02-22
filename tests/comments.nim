import compiler/parser
include ../src/rules/comments
import utils/helpers
import unittest2

suite "Unit tests for comments rule":

  checkpoint "Initializing the tests"
  const
    validOptions: seq[string] = @["pattern", "^FIXME"]
    invalidOptions = @["randomoption", "anotheroption", "thirdoption"]
    invalidNimCode = "var a = 1"
    validNimCode = "var a = 1"

  setLogger()

  let
    (nimCache, nimConfig) = setNim()
  var
    validCode = parseString(validNimCode, nimCache, nimConfig)
    invalidCode = parseString(invalidNimCode, nimCache, nimConfig)
    ruleOptions = RuleOptions(parent: true, fileName: "tests/invalid/comments.nim",
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
    ruleOptions.fileName = "tests/valid/comments.nim"
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
    ruleOptions.fileName = "tests/invalid/comments.nim"
    ruleCheck(invalidCode, invalidCode, ruleOptions)
    check:
      ruleOptions.amount > 0

  test "Checking search type of the rule":
    checkpoint "Checking search type of the rule with the invalid code."
    ruleOptions.parent = true
    ruleOptions.ruleType = search
    ruleOptions.negation = false
    ruleOptions.amount = 0
    ruleOptions.fileName = "tests/invalid/comments.nim"
    ruleCheck(invalidCode, invalidCode, ruleOptions)
    check:
      ruleOptions.amount == 0
    checkpoint "Checking search type of the rule with the valid code."
    ruleOptions.parent = true
    ruleOptions.fileName = "tests/valid/comments.nim"
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
    ruleOptions.fileName = "tests/invalid/comments.nim"
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

  test "Checking fix type of the rule.":
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
