# Copyright © 2023-2024 Bartek Jasicki
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
import std/[macros, os, strformat, strutils, times]
# External modules imports
import compiler/[idents, llstream, options, parser, pathutils]
import colored_logger
# Internal modules imports
import config, rules, utils

# Load the program's rules
macro importRules() =
  ## Import the program'r rules into the program's code. It walks trought
  ## files in the directory rules and import each with extension `nim` into
  ## the program.
  ##
  ## Returns the list of import statements with the program's rules code as
  ## modules.
  result = newStmtList()
  for file in walkDir(dir = getProjectPath().parentDir & DirSep & "src" &
      DirSep & "rules"):
    if file.path.endsWith(suffix = ".nim"):
      result.add nnkImportStmt.newTree(children =
        newIdentNode(i = file.path)
      )
importRules()

proc main() {.raises: [], tags: [ReadIOEffect, WriteIOEffect, RootEffect],
    contractual.} =
  ## The main procedure of the program
  # Set the logger, where the program output will be send
  body:
    let
      startTime: float = cpuTime()
      logger: ConsoleLogger = newColoredLogger(
        fmtStr = "[$time] $levelname ")
    addHandler(handler = logger)
    setLogFilter(lvl = lvlInfo)
    try:
      info(args = "Starting nimalyzer ver 0.8")
    except Exception:
      abortProgram(message = "Can't log messages.")
    # No configuration file specified, quit from the program
    if paramCount() == 0:
      abortProgram(message = "No configuration file specified. Please run the program with path to the config file as an argument.")
    let
      nimCache: IdentCache = newIdentCache()
      nimConfig: ConfigRef = newConfigRef()
    nimConfig.options.excl(y = optHints)
    var
      resultCode: int = QuitSuccess
      configSections: int = 0
      globalShowSummary: bool = false
    # Check source code files with the selected rules
    block checkingCode:
      while configSections > -1:
        # Read the configuration file and set the program
        var (sources, rules, fixCommand, maxResults, showSummary) = parseConfig(
            configFile = paramStr(i = 1), sections = configSections)
        if showSummary:
          globalShowSummary = showSummary
        # Check if the lists of source code files and rules is set
        if sources.len == 0:
          abortProgram(message = "No files specified to check. Please enter any files names to the configuration file.")
        if rules.len == 0:
          abortProgram(message = "No rules specified to check. Please enter any rule configuration to the configuration file.")
        # If the first element on the list of rules if a custom message, show it
        # once and remove from the list
        if rules[0].kind == ConfigKind.message:
          message(text = rules[0].text)
          rules.delete(i = 0)
        for i, source in sources:
          message(text = "[" & $(i + 1) & "/" & $sources.len & "] Parsing '" &
              source & "'")
          var codeParser: Parser = Parser()
          try:
            # Try to convert the source code file to AST
            let fileName: AbsoluteFile = toAbsolute(file = source,
                base = toAbsoluteDir(path = getCurrentDir()))
            try:
              openParser(p = codeParser, filename = fileName,
                  inputStream = llStreamOpen(filename = fileName,
                  mode = fmRead), cache = nimCache, config = nimConfig)
            except IOError, ValueError, KeyError, Exception:
              abortProgram(message = "Can't open file '" & source &
                  "' to parse. Reason: " & getCurrentExceptionMsg())
            try:
              let astNode: PNode = codeParser.parseAll
              codeParser.closeParser
              var
                currentRule: RuleOptions = RuleOptions(fileName: source,
                  fixCommand: fixCommand, identsCache: nimCache)
                index: Natural = 0
              # Check the converted source code with each selected rule
              for rule in rules:
                if rule.kind == ConfigKind.message:
                  message(text = rule.text)
                  continue
                message(text = "Parsing rule [" & $(index + 1) & "/" &
                    $rules.len & "]" & (
                    if rule.negation: " negation " else: " ") & $rule.ruleType &
                    " rule '" & rule.name & "' with options: '" &
                    rule.options.join(sep = ", ") & "'.", level = lvlDebug)
                index.inc
                currentRule.options = rule.options
                currentRule.negation = rule.negation
                currentRule.ruleType = rule.ruleType
                currentRule.amount = (if rule.ruleType ==
                    RuleTypes.check: 1 else: 0)
                currentRule.enabled = true
                currentRule.parent = true
                currentRule.forceFixCommand = rule.forceFixCommand
                currentRule.maxResults = maxResults
                currentRule.explanation = rule.explanation
                rulesList[rule.index].checkProc(astNode = astNode,
                    parentNode = astNode, rule = currentRule)
                if currentRule.amount < 1:
                  if currentRule.ruleType == fix:
                    writeFile(filename = currentRule.fileName,
                        content = $astNode)
                  else:
                    resultCode = QuitFailure
                maxResults = currentRule.maxResults
                if maxResults == 0:
                  message(text = "The limit of the maximum amount of the program's reports reached.",
                      level = lvlInfo)
                  break checkingCode
            except ValueError, IOError, KeyError, Exception:
              abortProgram(message = "The file '" & source &
                  "' can't be parsed to AST. Reason: ", e = getCurrentException())
          except OSError:
            abortProgram(message = "Can't parse file '" & source &
                "'. Reason: ", e = getCurrentException())
    if globalShowSummary:
      message(text = "========")
      message(text = "SUMMARY:")
      let
        timeTaken: float = cpuTime() - startTime
        memUsage: float = getMaxMem().float / 1048576.0
      try:
        message(text = "Time taken: {timeTaken:06.3f} sec(s)".fmt)
        message(text = "Max memory usage: {memUsage:06.3f} MiB".fmt)
      except:
        abortProgram(message = "Can't show the program's summary. Reason: ",
            e = getCurrentException())
    message(text = "Stopping nimalyzer.")
    quit resultCode

when isMainModule:
  main()
