discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule comments requires at maximum 2 options, but 3 provided: 'randomoption, anotheroption, thirdoption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: Comment at line: 1 doesn't match the pattern '^FIXME'.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: Comment at line: 1 match the pattern '^FIXME'.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: Comments which match the pattern not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: Comments which match the pattern not found.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: Comment at line: 1 doesn't match the pattern '^FIXME'.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: Comment at line: 1 doesn't match the pattern '^FIXME'.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Comments which match the pattern found found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Comments which match the pattern found found: 0
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: Comment at line: 1 doesn't match the pattern '^FIXME'.
NOTICE: Comments which doesn't match the pattern found found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Comment at line: 1 doesn't match the pattern '^FIXME'.
NOTICE: Comments which doesn't match the pattern found found: 1
INFO: Checking fix type of the rule.
ERROR: Comment at line: 2 doesn't match the pattern '^FIXME'.
INFO: Checking negative fix type of the rule.
ERROR: Comment at line: 1 match the pattern '^FIXME'.'''
"""

import std/logging
import compiler/parser
import ../../src/rules/comments
import ../../src/rules
import ../helpers

const
  validOptions: seq[string] = @["pattern", "^FIXME"]
  invalidOptions = @["randomoption", "anotheroption", "thirdoption"]
  invalidNimCode = "var a = 1"
  validNimCode = "var a = 1"

setLogger()

info("Checking the rule's options validation.")
try:
  assert not validateOptions(ruleSettings, invalidOptions)
except AssertionDefect:
  echo "Failed to catch invalid rule's options."
try:
  assert validateOptions(ruleSettings, validOptions)
except AssertionDefect:
  echo "Failed to validate rule's options."

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

# check rule tests
info("Checking check type of the rule with the invalid code.")
ruleCheck(invalidCode, invalidCode, ruleOptions)
try:
  assert ruleOptions.amount == 0
except AssertionDefect:
  echo "Check of invalid code for rule '" & ruleSettings.name &
      "' failed, expected result: 0, received: " & $ruleOptions.amount
info("Checking check type of the rule with the valid code.")
ruleOptions.parent = true
ruleOptions.fileName = "tests/tcomments/valid.nim"
ruleCheck(validCode, validCode, ruleOptions)
try:
  assert ruleOptions.amount > 0
except AssertionDefect:
  echo "Check of valid code for rule '" & ruleSettings.name &
      "' failed, expected result larger than 0, received: " &
      $ruleOptions.amount
# negative check rule tests
info("Checking negative check type of the rule with the valid code.")
ruleOptions.parent = true
ruleOptions.negation = true
ruleOptions.amount = 0
ruleCheck(validCode, validCode, ruleOptions)
try:
  assert ruleOptions.amount == 0
except AssertionDefect:
  echo "Negative check of valid code for rule '" & ruleSettings.name &
      "' failed, expected result: 0, received: " & $ruleOptions.amount
info("Checking negative check type of the rule with the invalid code.")
ruleOptions.parent = true
ruleOptions.fileName = "tests/tcomments/invalid.nim"
ruleCheck(invalidCode, invalidCode, ruleOptions)
try:
  assert ruleOptions.amount > 0
except AssertionDefect:
  echo "Negative check of invalid code for rule '" & ruleSettings.name &
      "' failed, expected result larger than 0, received: " &
      $ruleOptions.amount
# search rule tests
info("Checking search type of the rule with the invalid code.")
ruleOptions.parent = true
ruleOptions.ruleType = search
ruleOptions.negation = false
ruleOptions.amount = 0
ruleOptions.fileName = "tests/tcomments/invalid.nim"
ruleCheck(invalidCode, invalidCode, ruleOptions)
try:
  assert ruleOptions.amount == 0
except AssertionDefect:
  echo "Search for invalid code for rule '" & ruleSettings.name &
      "' failed, expected result: 0, received: " & $ruleOptions.amount
info("Checking search type of the rule with the valid code.")
ruleOptions.parent = true
ruleCheck(validCode, validCode, ruleOptions)
try:
  assert ruleOptions.amount > 0
except AssertionDefect:
  echo "Search for valid code for rule '" & ruleSettings.name &
      "' failed, expected result greater than 0, received: " &
      $ruleOptions.amount
# negative search rule tests
info("Checking negative search type of the rule with the valid code.")
ruleOptions.parent = true
ruleOptions.negation = true
ruleOptions.amount = 0
ruleCheck(validCode, validCode, ruleOptions)
try:
  assert ruleOptions.amount == 0
except AssertionDefect:
  echo "Negative search for valid code for rule '" & ruleSettings.name &
      "' failed, expected result: 0, received: " & $ruleOptions.amount
info("Checking negative search type of the rule with the invalid code.")
ruleOptions.parent = true
ruleCheck(invalidCode, invalidCode, ruleOptions)
try:
  assert ruleOptions.amount == 1
except AssertionDefect:
  echo "Negative search for invalid code for rule '" & ruleSettings.name &
      "' failed, expected result: 1, received: " & $ruleOptions.amount
# count rule tests
info("Checking count type of the rule with the invalid code.")
ruleOptions.parent = true
ruleOptions.ruleType = count
ruleOptions.negation = false
ruleOptions.amount = 0
ruleCheck(invalidCode, invalidCode, ruleOptions)
try:
  assert ruleOptions.amount == 1
except AssertionDefect:
  echo "Counting of invalid code for rule '" & ruleSettings.name &
      "' failed, expected result: 1, received: " & $ruleOptions.amount
info("Checking count type of the rule with the valid code.")
ruleOptions.parent = true
ruleOptions.amount = 0
ruleCheck(validCode, validCode, ruleOptions)
try:
  assert ruleOptions.amount == 1
except AssertionDefect:
  echo "Counting of valid code for rule '" & ruleSettings.name &
      "' failed, expected result: 1, received: " & $ruleOptions.amount
# negative count rule tests
info("Checking negative count type of the rule with the invalid code.")
ruleOptions.parent = true
ruleOptions.negation = true
ruleOptions.amount = 0
ruleCheck(invalidCode, invalidCode, ruleOptions)
try:
  assert ruleOptions.amount == 1
except AssertionDefect:
  echo "Negative counting of invalid code for rule '" & ruleSettings.name &
      "' failed, expected result: 1, received: " & $ruleOptions.amount
info("Checking negative count type of the rule with the valid code.")
ruleOptions.parent = true
ruleOptions.amount = 0
ruleCheck(validCode, validCode, ruleOptions)
try:
  assert ruleOptions.amount == 1
except AssertionDefect:
  echo "Negative counting of valid code for rule '" & ruleSettings.name &
      "' failed, expected result: 1, received: " & $ruleOptions.amount
# fix rule tests
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
## negative fix rule tests
#info("Checking negative fix type of the rule.")
#ruleOptions.parent = true
#ruleOptions.negation = true
#ruleOptions.amount = 0
#let oldValidCode = copyTree(validCode)
#ruleCheck(validCode, validCode, ruleOptions)
#try:
#  assert $invalidCode == $validCode
#except AssertionDefect:
#  echo "Fixing the valid code with negation for rule '" &
#      ruleSettings.name & "' failed. Invalid code: " & $invalidCode &
#      "\nshould be: " & $validCode
#validCode = copyTree(oldValidCode)

removeFile("tests/tcomments/invalid.nim")
removeFile("tests/tcomments/valid.nim")
