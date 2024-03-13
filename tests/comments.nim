# Copyright © 2024 Bartek Jasicki
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS AND CONTRIBUTORS ''AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Provides unit tests for comments rule

import compiler/parser
include ../src/rules/comments
import utils/helpers
import unittest2

suite "Unit tests for comments rule":

  checkpoint "Initializing the tests"
  const
    validOptions: seq[string] = @["pattern", "^FIXME"]
    invalidOptions: seq[string] = @["randomoption", "anotheroption", "thirdoption"]
    invalidNimCode: string = "var a = 1"
    validNimCode: string = "var a = 1"

  setLogger()

  let
    (nimCache, nimConfig) = setNim()
  var
    validCode: PNode = parseString(s = validNimCode, cache = nimCache,
        config = nimConfig)
    invalidCode: PNode = parseString(s = invalidNimCode, cache = nimCache,
        config = nimConfig)
    ruleOptions: RuleOptions = RuleOptions(parent: true,
        fileName: "tests/invalid/comments.nim", negation: false, ruleType: check,
        options: validOptions, amount: 0,
        enabled: true, maxResults: Natural.high)

  test "Validate invalid rule's options":
    check:
      not validateOptions(rule = ruleSettings, options = invalidOptions)

  test "Validate valid rule's options":
    check:
      validateOptions(rule = ruleSettings, options = validOptions)

  test "Checking the check type of the rule with the invalid code":
    ruleCheck(astNode = invalidCode, parentNode = invalidCode,
        rule = ruleOptions)
    check:
      ruleOptions.amount == 0

  test "Checking the check type of the rule with the valid code":
    ruleOptions.parent = true
    ruleOptions.fileName = "tests/valid/comments.nim"
    ruleCheck(astNode = validCode, parentNode = validCode, rule = ruleOptions)
    check:
      ruleOptions.amount > 0

  test "Checking the negative check type of the rule with the valid code":
    ruleOptions.parent = true
    ruleOptions.negation = true
    ruleOptions.amount = 0
    ruleCheck(astNode = validCode, parentNode = validCode, rule = ruleOptions)
    check:
      ruleOptions.amount == 0

  test "Checking the negative check type of the rule with the invalid code":
    ruleOptions.parent = true
    ruleOptions.fileName = "tests/invalid/comments.nim"
    ruleCheck(astNode = invalidCode, parentNode = invalidCode,
        rule = ruleOptions)
    check:
      ruleOptions.amount > 0

  test "Checking search type of the rule with the invalid code.":
    ruleOptions.parent = true
    ruleOptions.ruleType = search
    ruleOptions.negation = false
    ruleOptions.amount = 0
    ruleOptions.fileName = "tests/invalid/comments.nim"
    ruleCheck(astNode = invalidCode, parentNode = invalidCode,
        rule = ruleOptions)
    check:
      ruleOptions.amount == 0

  test "Checking search type of the rule with the valid code.":
    ruleOptions.parent = true
    ruleOptions.fileName = "tests/valid/comments.nim"
    ruleCheck(astNode = validCode, parentNode = validCode, rule = ruleOptions)
    check:
      ruleOptions.amount > 0

  test "Checking negative search type of the rule with the valid code.":
    ruleOptions.parent = true
    ruleOptions.negation = true
    ruleOptions.amount = 0
    ruleCheck(astNode = validCode, parentNode = validCode, rule = ruleOptions)
    check:
      ruleOptions.amount == 0

  test "Checking negative search type of the rule with the invalid code.":
    ruleOptions.parent = true
    ruleOptions.fileName = "tests/invalid/comments.nim"
    ruleCheck(astNode = invalidCode, parentNode = invalidCode,
        rule = ruleOptions)
    check:
      ruleOptions.amount == 1

  test "Checking count type of the rule with the invalid code.":
    ruleOptions.parent = true
    ruleOptions.ruleType = count
    ruleOptions.negation = false
    ruleOptions.amount = 0
    ruleOptions.fileName = "tests/invalid/comments.nim"
    ruleCheck(astNode = invalidCode, parentNode = invalidCode,
        rule = ruleOptions)
    check:
      ruleOptions.amount == 0

  test "Checking count type of the rule with the valid code.":
    ruleOptions.parent = true
    ruleOptions.amount = 0
    ruleOptions.fileName = "tests/valid/comments.nim"
    ruleCheck(astNode = validCode, parentNode = validCode, rule = ruleOptions)
    check:
      ruleOptions.amount == 1

  test "Checking negative count type of the rule with the invalid code.":
    ruleOptions.parent = true
    ruleOptions.negation = true
    ruleOptions.amount = 0
    ruleOptions.fileName = "tests/invalid/comments.nim"
    ruleCheck(astNode = invalidCode, parentNode = invalidCode,
        rule = ruleOptions)
    check:
      ruleOptions.amount == 1

  test "Checking negative count type of the rule with the valid code.":
    ruleOptions.parent = true
    ruleOptions.amount = 0
    ruleOptions.fileName = "tests/valid/comments.nim"
    ruleCheck(astNode = validCode, parentNode = validCode, rule = ruleOptions)
    check:
      ruleOptions.amount == 0

  test "Checking fix type of the rule.":
    ruleOptions.parent = true
    ruleOptions.ruleType = fix
    ruleOptions.negation = false
    ruleOptions.amount = 0
    ruleOptions.identsCache = nimCache
    let oldInvalidCode: PNode = copyTree(src = invalidCode)
    ruleCheck(astNode = invalidCode, parentNode = invalidCode,
        rule = ruleOptions)
    check:
      $invalidCode == $validCode
    invalidCode = copyTree(src = oldInvalidCode)
