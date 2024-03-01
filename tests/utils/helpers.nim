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

## Provides various code related to the project's unit tests. Mostly the whole
## structure of tests for the program's rules.

import compiler/[idents, llstream, options, parser, pathutils]
import ../../src/rules
import contracts, unittest2

type DisabledChecks* = enum
  invalidSearch, fixTests, negativeFix

proc setLogger*() {.sideEffect, raises: [], tags: [], contractual.} =
  ensure:
    getHandlers().len > 0
  body:
    if getHandlers().len > 0:
      return
    let logger = newConsoleLogger(fmtStr = "$levelname: ")
    addHandler(handler = logger)
    setLogFilter(lvl = lvlInfo)

proc setNim*(): tuple[cache: IdentCache, config: ConfigRef] {.sideEffect,
    raises: [], tags: [], contractual.} =
  let
    nimCache = newIdentCache()
    nimConfig = newConfigRef()
  nimConfig.options.excl(y = optHints)
  return (nimCache, nimConfig)

template runRuleTest*(files, validOptions, invalidOptions: seq[string];
    disabledChecks: set[DisabledChecks] = {}) =

  suite "Unit tests for " & ruleSettings.name & " rule":

    checkpoint "Initializing the tests"
    setLogger()
    let
      (nimCache, nimConfig) = setNim()
    for sourceFile in files:
      var
        codeParser: Parser = Parser()
        fileName = toAbsolute(file = sourceFile & ".nim",
            base = toAbsoluteDir(path = getCurrentDir() & DirSep & "tests" &
            DirSep & "valid"))
      openParser(p = codeParser, filename = fileName,
          inputStream = llStreamOpen(filename = fileName, mode = fmRead),
          cache = nimCache, config = nimConfig)
      var validCode: PNode = codeParser.parseAll
      codeParser.closeParser
      var fileName2 = toAbsolute(file = sourceFile & ".nim",
          base = toAbsoluteDir(path = getCurrentDir() & DirSep & "tests" &
          DirSep & "invalid"))
      openParser(p = codeParser, filename = fileName2,
          inputStream = llStreamOpen(filename = fileName2, mode = fmRead),
          cache = nimCache, config = nimConfig)
      var invalidCode: PNode = codeParser.parseAll
      codeParser.closeParser
      var ruleOptions = RuleOptions(parent: true,
          fileName: "tests/tcomments/test.nim", negation: false,
          ruleType: check, options: validOptions, amount: 0, enabled: true,
          maxResults: Natural.high)

      test "Checking the rule's options validation.":
        checkpoint "Validate invalid rule's options"
        check:
          not validateOptions(rule = ruleSettings, options = invalidOptions)
        checkpoint "Validate valid rule's options"
        check:
          validateOptions(rule = ruleSettings, options = validOptions)

      test "Checking check type of the rule":
        checkpoint "Checking the check type of the rule with the invalid code"
        ruleCheck(astNode = invalidCode, parentNode = invalidCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount == 0
        checkpoint "Checking the check type of the rule with the valid code"
        ruleOptions.parent = true
        ruleCheck(astNode = validCode, parentNode = validCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount > 0

      test "Checking negative check type of the rule":
        checkpoint "Checking the negative check type of the rule with the valid code"
        ruleOptions.parent = true
        ruleOptions.negation = true
        ruleOptions.amount = 0
        ruleCheck(astNode = validCode, parentNode = validCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount == 0
        checkpoint "Checking the negative check type of the rule with the invalid code"
        ruleOptions.parent = true
        ruleCheck(astNode = invalidCode, parentNode = invalidCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount > 0

      test "Checking search type of the rule":
        checkpoint "Checking search type of the rule with the invalid code."
        ruleOptions.parent = true
        ruleOptions.ruleType = search
        ruleOptions.negation = false
        ruleOptions.amount = 0
        if invalidSearch in disabledChecks:
          echo "Test for search type of the rule with invalid code skipped"
          skip()
        else:
          ruleCheck(astNode = invalidCode, parentNode = invalidCode,
              rule = ruleOptions)
          check:
            ruleOptions.amount == 0
          checkpoint "Checking search type of the rule with the valid code."
          ruleOptions.parent = true
          ruleCheck(astNode = validCode, parentNode = validCode,
              rule = ruleOptions)
          check:
            ruleOptions.amount > 0

      test "Checking negative search type of the rule":
        checkpoint "Checking negative search type of the rule with the valid code."
        ruleOptions.parent = true
        ruleOptions.negation = true
        ruleOptions.amount = 0
        ruleCheck(astNode = validCode, parentNode = validCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount == 0
        checkpoint "Checking negative search type of the rule with the invalid code."
        ruleOptions.parent = true
        ruleCheck(astNode = invalidCode, parentNode = invalidCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount > 0

      test "Checking count type of the rule":
        checkpoint "Checking count type of the rule with the invalid code."
        ruleOptions.parent = true
        ruleOptions.ruleType = count
        ruleOptions.negation = false
        ruleOptions.amount = 0
        ruleCheck(astNode = invalidCode, parentNode = invalidCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount == 1
        checkpoint "Checking count type of the rule with the valid code."
        ruleOptions.parent = true
        ruleOptions.amount = 0
        ruleCheck(astNode = validCode, parentNode = validCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount == 1

      test "Checking negative count type of the rule":
        checkpoint "Checking negative count type of the rule with the invalid code."
        ruleOptions.parent = true
        ruleOptions.negation = true
        ruleOptions.amount = 0
        ruleCheck(astNode = invalidCode, parentNode = invalidCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount == 1
        checkpoint "Checking negative count type of the rule with the valid code."
        ruleOptions.parent = true
        ruleOptions.amount = 0
        ruleCheck(astNode = validCode, parentNode = validCode,
            rule = ruleOptions)
        check:
          ruleOptions.amount == 1

      test "Checking fix type of the rule":
        if fixTests in disabledChecks:
          echo "Test for fix type of the rule skipped."
          skip()
        else:
          checkpoint "Checking fix type of the rule."
          ruleOptions.parent = true
          ruleOptions.ruleType = fix
          ruleOptions.negation = false
          ruleOptions.amount = 0
          ruleOptions.identsCache = nimCache
          let oldInvalidCode = copyTree(src = invalidCode)
          ruleCheck(astNode = invalidCode, parentNode = invalidCode,
              rule = ruleOptions)
          check:
            $invalidCode == $validCode
          invalidCode = copyTree(src = oldInvalidCode)

      test "Checking negative fix type of the rule":
        if fixTests in disabledChecks or negativeFix in disabledChecks:
          echo "Test for negative fix type of the rule skipped."
          skip()
        else:
          checkpoint "Checking negative fix type of the rule."
          ruleOptions.parent = true
          ruleOptions.negation = true
          ruleOptions.amount = 0
          let oldValidCode = copyTree(src = validCode)
          ruleCheck(astNode = validCode, parentNode = validCode,
              rule = ruleOptions)
          check:
            $invalidCode == $validCode
          validCode = copyTree(src = oldValidCode)
