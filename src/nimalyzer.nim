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
import compiler/[ast, idents, llstream, options, parser, pathutils]
import contracts
# Internal modules imports
import rules
# Nimalyzer rules imports
import rules/[hasdoc, hasentity, haspragma, namedparams, paramsused, vardeclared]

proc main() {.raises: [], tags: [ReadIOEffect, WriteIOEffect, RootEffect],
    contractual.} =
  ## The main procedure of the program
  # Set the logger, where the program output will be send
  body:
    let logger: ConsoleLogger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
    addHandler(handler = logger)
    setLogFilter(lvl = lvlInfo)

    proc message(text: string; level: Level = lvlInfo) {.raises: [], tags: [
        RootEffect], contractual.} =
      ## Log the selected message. If error happens during logging, print the
      ## error message and quit the program
      ##
      ## * text  - the message to log
      ## * level - the log level of the message. Default value is lvlInfo
      require:
        text.len > 0
      body:
        try:
          log(level = level, args = text)
        except Exception:
          echo "Can't log the message. Reason: ", getCurrentExceptionMsg()
          echo "Stopping nimalyzer"
          quit QuitFailure

    proc abortProgram(message: string; e: ref Exception = nil) {.gcsafe,
        raises: [], tags: [RootEffect], contractual.} =
      ## Log the message and stop the program
      ##
      ## * message - the message to log
      ## * e       - the exception which occured if any.
      require:
        message.len > 0
      body:
        discard errorMessage(text = message, e = e)
        message(text = "Stopping nimalyzer.")
        quit QuitFailure

    try:
      info(args = "Starting nimalyzer ver 0.2.0")
    except Exception:
      abortProgram(message = "Can't log messages.")

    # No configuration file specified, quit from the program
    if paramCount() == 0:
      abortProgram(message = "No configuration file specified. Please run the program with path to the config file as an argument.")
    const rulesList = {haspragma.ruleName: (haspragma.ruleCheck,
        haspragma.validateOptions), hasentity.ruleName: (hasentity.ruleCheck,
        hasentity.validateOptions), paramsused.ruleName: (paramsused.ruleCheck,
        paramsused.validateOptions), namedparams.ruleName: (
        namedparams.ruleCheck, namedparams.validateOptions), hasdoc.ruleName: (
        hasdoc.ruleCheck, hasdoc.validateOptions), varDeclared.ruleName: (
        varDeclared.ruleCheck, varDeclared.validateOptions)}.toTable
    # Read the configuration file and set the program
    let configFile: string = paramStr(i = 1)
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
      ## Add the selected file as a source code to check for the program
      ##
      ## * fileName - the path to the file which will be added
      ## * sources  - the list of source code files to check
      ##
      ## Returns the updated parameter sources
      require:
        fileName.len > 0
      body:
        if fileName notin sources:
          sources.add(y = fileName)
          message(text = "Added file '" & fileName &
              "' to the list of files to check.", level = lvlDebug)

    try:
      # Read the program's configuration
      for line in configFile.lines:
        # Comment line, skip
        if line.startsWith(prefix = '#') or line.len == 0:
          continue
        # Set the program's verbosity
        elif line.startsWith(prefix = "verbosity"):
          try:
            setLogFilter(lvl = parseEnum[Level](s = line[10..^1]))
            message(text = "Setting the program verbosity to '" & line[10..^1] &
                "'.", level = lvlDebug)
          except ValueError:
            abortProgram(message = "Invalid value set in configuration file for the program verbosity level.")
        # Set the file to which the program's output will be logged
        elif line.startsWith(prefix = "output"):
          let fileName = unixToNativePath(path = line[7..^1])
          addHandler(handler = newFileLogger(filename = fileName,
              fmtStr = "[$time] - $levelname: "))
          message(text = "Added file '" & fileName & "' as log file.",
              level = lvlDebug)
        # Set the source code file to check
        elif line.startsWith(prefix = "source"):
          let fileName = unixToNativePath(path = line[7..^1])
          addFile(fileName = fileName, sources = sources)
        # Set the source code files to check
        elif line.startsWith(prefix = "files"):
          try:
            for fileName in walkFiles(pattern = line[6..^1]):
              addFile(fileName = fileName, sources = sources)
          except OSError:
            abortProgram(message = "Can't parse setting: '" & line &
                "'. Reason: ", e = getCurrentException())
        # Set the source code files to check, the second option
        elif line.startsWith(prefix = "directory"):
          try:
            for fileName in walkDirRec(dir = line[10..^1]):
              addFile(fileName = fileName, sources = sources)
          except OSError:
            abortProgram(message = "Can't add files to check. Reason: ",
                e = getCurrentException())
        # Set the program's rule to test the code
        elif line.startsWith(prefix = "check") or line.startsWith(
            prefix = "search") or line.startsWith(prefix = "count"):
          var configRule = initOptParser(cmdline = line)
          configRule.next
          let ruleType: RuleTypes = try:
              parseEnum[RuleTypes](s = configRule.key)
            except ValueError:
              none
          if ruleType == none:
            abortProgram(message = "Unknown type of rule: '" & configRule.key & "'.")
          configRule.next
          var newRule = RuleData(name: configRule.key.toLowerAscii, options: @[
            ], negation: false, ruleType: ruleType)
          if newRule.name == "not":
            newRule.negation = true
            configRule.next
            newRule.name = configRule.key.toLowerAscii
          if not rulesList.hasKey(key = newRule.name):
            abortProgram(message = "No rule named '" & newRule.name & "' available.")
          while true:
            configRule.next()
            if configRule.kind == cmdEnd:
              break
            newRule.options.add(y = configRule.key)
          try:
            if not rulesList[newRule.name][1](options = newRule.options):
              abortProgram(message = "Invalid options for rule '" &
                  newRule.name & "'.")
          except KeyError:
            abortProgram(message = "Can't validate rule parameters. Reason: ",
                e = getCurrentException())
          rules.add(y = newRule)
          message(text = "Added" & (if rules[
              ^1].negation: " negation " else: " ") & $rules[^1].ruleType &
              " rule '" & rules[^1].name & "' with options: '" & rules[
              ^1].options.join(", ") & "' to the list of rules to check.",
              level = lvlDebug)
    except IOError:
      abortProgram(message = "The specified configuration file '" & configFile & "' doesn't exist.")
    # Check if the lists of source code files and rules is set
    if sources.len == 0:
      abortProgram(message = "No files specified to check. Please enter any files names to the configuration file.")
    if rules.len == 0:
      abortProgram(message = "No rules specified to check. Please enter any rule configuration to the configuration file.")
    let
      nimCache: IdentCache = newIdentCache()
      nimConfig: ConfigRef = newConfigRef()
    nimConfig.options.excl(y = optHints)
    var resultCode: int = QuitSuccess
    # Check source code files with the selected rules
    for i, source in sources.pairs:
      message(text = "[" & $(i + 1) & "/" & $sources.len & "] Parsing '" &
          source & "'")
      var codeParser: Parser
      try:
        # Try to convert the source code file to AST
        let fileName: AbsoluteFile = toAbsolute(file = source, base = toAbsoluteDir(
            path = getCurrentDir()))
        try:
          openParser(p = codeParser, filename = fileName,
              inputStream = llStreamOpen(filename = fileName, mode = fmRead),
                  cache = nimCache,
              config = nimConfig)
        except IOError, ValueError, KeyError, Exception:
          abortProgram(message = "Can't open file '" & source &
              "' to parse. Reason: " & getCurrentExceptionMsg())
        try:
          let astTree: PNode = codeParser.parseAll
          codeParser.closeParser
          var options: RuleOptions = RuleOptions(fileName: source)
          # Check the converted source code with each selected rule
          for index, rule in rules.pairs:
            message(text = "Parsing rule [" & $(index + 1) & "/" & $rules.len &
                "]" & (if rule.negation: " negation " else: " ") &
                $rule.ruleType & " rule '" & rule.name & "' with options: '" &
                rule.options.join(sep = ", ") & "'.", level = lvlDebug)
            options.options = rule.options
            options.negation = rule.negation
            options.ruleType = rule.ruleType
            options.amount = 0
            options.enabled = true
            options.parent = true
            rulesList[rule.name][0](astTree = astTree, options = options)
            if options.amount < 1:
              resultCode = QuitFailure
        except ValueError, IOError, KeyError, Exception:
          abortProgram(message = "The file '" & source &
              "' can't be parsed to AST. Reason: ", e = getCurrentException())
      except OSError:
        abortProgram(message = "Can't parse file '" & source & "'. Reason: ",
            e = getCurrentException())
    message(text = "Stopping nimalyzer.")
    quit resultCode

when isMainModule:
  main()
