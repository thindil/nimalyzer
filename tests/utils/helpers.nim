import compiler/[idents, llstream, options, parser, pathutils]
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

template runRuleTest*(files: seq[string]; disabledChecks: set[DisabledChecks] = {}) =

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
        if invalidSearch in disabledChecks:
          echo "Test for search type of the rule with invalid code skipped"
          skip()
        else:
          ruleCheck(invalidCode, invalidCode, ruleOptions)
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
          ruleOptions.amount > 0

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
          let oldInvalidCode = copyTree(invalidCode)
          ruleCheck(invalidCode, invalidCode, ruleOptions)
          check:
            $invalidCode == $validCode
          invalidCode = copyTree(oldInvalidCode)

      test "Checking negative fix type of the rule":
        if fixTests in disabledChecks or negativeFix in disabledChecks:
          echo "Test for negative fix type of the rule skipped."
          skip()
        else:
          checkpoint "Checking negative fix type of the rule."
          ruleOptions.parent = true
          ruleOptions.negation = true
          ruleOptions.amount = 0
          let oldValidCode = copyTree(validCode)
          ruleCheck(validCode, validCode, ruleOptions)
          check:
            $invalidCode == $validCode
          validCode = copyTree(oldValidCode)
