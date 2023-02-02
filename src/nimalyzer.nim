# Copyright © 2023 Bartek Jasicki
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

## This is the main module of the program.

# Standard library imports
import std/[logging, os, parseopt, strutils, tables]
# External modules imports
import compiler/[idents, llstream, options, parser, pathutils]
import contracts
# Internal modules imports
import rules
# Nimalyzer rules imports
import rules/[haspragma, hasentity, namedparams, paramsused]

proc main() {.raises: [], tags: [ReadIOEffect, WriteIOEffect, RootEffect],
    contractual.} =
  # Set the logger, where the program output will be send
  body:
    let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
    addHandler(handler = logger)
    setLogFilter(lvl = lvlInfo)

    proc message(text: string; level: Level = lvlInfo) {.raises: [], tags: [
        RootEffect], contractual.} =
      require:
        text.len > 0
      body:
        try:
          log(level, text)
        except Exception:
          echo "Can't log the message. Reason: ", getCurrentExceptionMsg()
          echo "Stopping nimalyzer"
          quit QuitFailure

    proc abortProgram(message: string) {.gcsafe, raises: [], tags: [RootEffect],
        contractual.} =
      require:
        message.len > 0
      body:
        message(text = message, level = lvlFatal)
        message(text = "Stopping nimalyzer.")
        quit QuitFailure

    try:
      info("Starting nimalyzer ver 0.1.0")
    except Exception:
      abortProgram("Can't log messages.")

    # No configuration file specified, quit from the program
    if paramCount() == 0:
      abortProgram("No configuration file specified. Please run the program with path to the config file as an argument.")
    const rulesList = {haspragma.ruleName: haspragma.ruleCheck,
        hasentity.ruleName: hasentity.ruleCheck,
        paramsused.ruleName: paramsused.ruleCheck,
        namedparams.ruleName: namedparams.ruleCheck}.toTable
    # Read the configuration file and set the program
    let configFile = paramStr(i = 1)
    type RuleData = object
      name: string
      options: seq[string]
      negation: bool
      ruleType: RuleTypes
    var
      sources: seq[string]
      rules: seq[RuleData]

    proc addFile(fileName: string; sources: var seq[string]) {.gcsafe, raises: [
        ], tags: [RootEffect], contractual.} =
      require:
        fileName.len > 0
      body:
        if fileName notin sources:
          sources.add(y = fileName)
          message(text = "Added file '" & fileName &
              "' to the list of files to check.", level = lvlDebug)

    try:
      for line in configFile.lines:
        if line.startsWith(prefix = '#') or line.len == 0:
          continue
        elif line.startsWith(prefix = "verbosity"):
          try:
            setLogFilter(lvl = parseEnum[Level](s = line[10..^1]))
            message(text = "Setting the program verbosity to '" & line[10..^1] &
                "'.", level = lvlDebug)
          except ValueError:
            abortProgram("Invalid value set in configuration file for the program verbosity level.")
        elif line.startsWith(prefix = "output"):
          let fileName = unixToNativePath(line[7..^1])
          addHandler(handler = newFileLogger(filename = fileName,
              fmtStr = "[$time] - $levelname: "))
          message(text = "Added file '" & fileName & "' as log file.",
              level = lvlDebug)
        elif line.startsWith(prefix = "source"):
          let fileName = unixToNativePath(line[7..^1])
          addFile(fileName = fileName, sources = sources)
        elif line.startsWith(prefix = "files"):
          for fileName in walkFiles(pattern = line[6..^1]):
            addFile(fileName = fileName, sources = sources)
        elif line.startsWith(prefix = "directory"):
          try:
            for fileName in walkDirRec(dir = line[10..^1]):
              addFile(fileName = fileName, sources = sources)
          except OSError:
            abortProgram("Can't add files to check. Reason: " &
                getCurrentExceptionMsg())
        elif line.startsWith(prefix = "check") or line.startsWith(
            prefix = "search") or line.startsWith(prefix = "count"):
          var configRule = initOptParser(cmdline = line)
          configRule.next
          let ruleType: RuleTypes = try:
              parseEnum[RuleTypes](s = configRule.key)
            except ValueError:
              none
          if ruleType == none:
            abortProgram("Unknown type of rule: '" & configRule.key & "'.")
          configRule.next
          var newRule = RuleData(name: configRule.key.toLowerAscii, options: @[
            ], negation: false, ruleType: ruleType)
          if newRule.name == "not":
            newRule.negation = true
            configRule.next
            newRule.name = configRule.key.toLowerAscii
          if not rulesList.hasKey(key = newRule.name):
            abortProgram("No rule named '" & newRule.name & "' available.")
          while true:
            configRule.next()
            if configRule.kind == cmdEnd:
              break
            newRule.options.add(y = configRule.key)
          rules.add(y = newRule)
          message(text = "Added" & (if rules[
              ^1].negation: " negation " else: " ") & $rules[^1].ruleType &
              " rule '" & rules[^1].name & "' with options: '" & rules[
              ^1].options.join(", ") & "' to the list of rules to check.",
              level = lvlDebug)
    except IOError:
      abortProgram("The specified configuration file '" & configFile & "' doesn't exist.")
    # Check if the lists of source code files and rules is set
    if sources.len == 0:
      abortProgram("No files specified to check. Please enter any files names to the configuration file.")
    if rules.len == 0:
      abortProgram("No rules specified to check. Please enter any rule configuration to the configuration file.")
    let
      nimCache = newIdentCache()
      nimConfig = newConfigRef()
    nimConfig.options.excl(optHints)
    var resultCode = QuitSuccess
    # Check source code files with the selected rules
    for i, source in sources.pairs:
      message(text = "[" & $(i + 1) & "/" & $sources.len & "] Parsing '" &
          source & "'")
      var codeParser: Parser
      try:
        let fileName = toAbsolute(file = source, base = toAbsoluteDir(
            path = getCurrentDir()))
        try:
          openParser(p = codeParser, filename = fileName, llStreamOpen(
              filename = fileName, mode = fmRead), cache = nimCache,
              config = nimConfig)
        except IOError, ValueError, KeyError, Exception:
          abortProgram("Can't open file '" & source &
              "' to parse. Reason: " & getCurrentExceptionMsg())
        try:
          let astTree = codeParser.parseAll
          codeParser.closeParser
          var options = RuleOptions(parent: true, fileName: source)
          for index, rule in rules.pairs:
            message(text = "Parsing rule [" & $(index + 1) & "/" & $rules.len &
                "]" & (if rule.negation: " negation " else: " ") &
                $rule.ruleType & " rule '" & rule.name & "' with options: '" &
                rule.options.join(", ") & "'.", level = lvlDebug)
            options.options = rule.options
            options.negation = rule.negation
            options.ruleType = rule.ruleType
            options.amount = 0
            if rulesList[rule.name](astTree = astTree, options = options) < 1:
              resultCode = QuitFailure
        except ValueError, IOError, KeyError, Exception:
          abortProgram("The file '" & source &
              "' can't be parsed to AST. Reason: " & getCurrentExceptionMsg())
      except OSError:
        abortProgram("Can't parse file '" & source & "'. Reason: " &
            getCurrentExceptionMsg())
    message(text = "Stopping nimalyzer.")
    quit resultCode

when isMainModule:
  main()
