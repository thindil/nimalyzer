import std/logging
import compiler/parser
import ../src/rules/comments
import ../src/rules
import utils/helpers
import unittest2

suite "Unit tests for comments module":

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
    ruleOptions = RuleOptions(parent: true, fileName: "tests/tcomments/invalid.nim",
        negation: false, ruleType: check, options: validOptions, amount: 0,
        enabled: true, maxResults: Natural.high)

  writeFile("tests/tcomments/valid.nim", "# FIXME comment to delete")
  writeFile("tests/tcomments/invalid.nim", "# Another comment")

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
    ruleOptions.fileName = "tests/tcomments/valid.nim"
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
    ruleOptions.fileName = "tests/tcomments/invalid.nim"
    ruleCheck(invalidCode, invalidCode, ruleOptions)
    check:
      ruleOptions.amount > 0

## search rule tests
#info("Checking search type of the rule with the invalid code.")
#ruleOptions.parent = true
#ruleOptions.ruleType = search
#ruleOptions.negation = false
#ruleOptions.amount = 0
#ruleOptions.fileName = "tests/tcomments/invalid.nim"
#ruleCheck(invalidCode, invalidCode, ruleOptions)
#try:
#  assert ruleOptions.amount == 0
#except AssertionDefect:
#  echo "Search for invalid code for rule '" & ruleSettings.name &
#      "' failed, expected result: 0, received: " & $ruleOptions.amount
#info("Checking search type of the rule with the valid code.")
#ruleOptions.parent = true
#ruleOptions.fileName = "tests/tcomments/valid.nim"
#ruleCheck(validCode, validCode, ruleOptions)
#try:
#  assert ruleOptions.amount > 0
#except AssertionDefect:
#  echo "Search for valid code for rule '" & ruleSettings.name &
#      "' failed, expected result greater than 0, received: " &
#      $ruleOptions.amount
## negative search rule tests
#info("Checking negative search type of the rule with the valid code.")
#ruleOptions.parent = true
#ruleOptions.negation = true
#ruleOptions.amount = 0
#ruleCheck(validCode, validCode, ruleOptions)
#try:
#  assert ruleOptions.amount == 0
#except AssertionDefect:
#  echo "Negative search for valid code for rule '" & ruleSettings.name &
#      "' failed, expected result: 0, received: " & $ruleOptions.amount
#info("Checking negative search type of the rule with the invalid code.")
#ruleOptions.parent = true
#ruleOptions.fileName = "tests/tcomments/invalid.nim"
#ruleCheck(invalidCode, invalidCode, ruleOptions)
#try:
#  assert ruleOptions.amount == 1
#except AssertionDefect:
#  echo "Negative search for invalid code for rule '" & ruleSettings.name &
#      "' failed, expected result: 1, received: " & $ruleOptions.amount
## count rule tests
#info("Checking count type of the rule with the invalid code.")
#ruleOptions.parent = true
#ruleOptions.ruleType = count
#ruleOptions.negation = false
#ruleOptions.amount = 0
#ruleCheck(invalidCode, invalidCode, ruleOptions)
#try:
#  assert ruleOptions.amount == 1
#except AssertionDefect:
#  echo "Counting of invalid code for rule '" & ruleSettings.name &
#      "' failed, expected result: 1, received: " & $ruleOptions.amount
#info("Checking count type of the rule with the valid code.")
#ruleOptions.parent = true
#ruleOptions.amount = 0
#ruleCheck(validCode, validCode, ruleOptions)
#try:
#  assert ruleOptions.amount == 1
#except AssertionDefect:
#  echo "Counting of valid code for rule '" & ruleSettings.name &
#      "' failed, expected result: 1, received: " & $ruleOptions.amount
## negative count rule tests
#info("Checking negative count type of the rule with the invalid code.")
#ruleOptions.parent = true
#ruleOptions.negation = true
#ruleOptions.amount = 0
#ruleCheck(invalidCode, invalidCode, ruleOptions)
#try:
#  assert ruleOptions.amount == 1
#except AssertionDefect:
#  echo "Negative counting of invalid code for rule '" & ruleSettings.name &
#      "' failed, expected result: 1, received: " & $ruleOptions.amount
#info("Checking negative count type of the rule with the valid code.")
#ruleOptions.parent = true
#ruleOptions.amount = 0
#ruleCheck(validCode, validCode, ruleOptions)
#try:
#  assert ruleOptions.amount == 1
#except AssertionDefect:
#  echo "Negative counting of valid code for rule '" & ruleSettings.name &
#      "' failed, expected result: 1, received: " & $ruleOptions.amount
## fix rule tests
#info("Checking fix type of the rule.")
#ruleOptions.parent = true
#ruleOptions.ruleType = fix
#ruleOptions.negation = false
#ruleOptions.amount = 0
#ruleOptions.identsCache = nimCache
#let oldInvalidCode = copyTree(invalidCode)
#ruleCheck(invalidCode, invalidCode, ruleOptions)
#try:
#  assert $invalidCode == $validCode
#except AssertionDefect:
#  echo "Fixing the invalid code for rule '" & ruleSettings.name &
#      "' failed. Invalid code: " & $invalidCode & "\nshould be: " & $validCode
#invalidCode = copyTree(oldInvalidCode)

removeFile("tests/tcomments/invalid.nim")
removeFile("tests/tcomments/valid.nim")
