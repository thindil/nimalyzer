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
import std/os
# External modules imports
import compiler/[idents, llstream, options, parser, pathutils]
# Internal modules imports
import config, rules, utils

proc main() {.raises: [], tags: [ReadIOEffect, WriteIOEffect, RootEffect],
    contractual.} =
  ## The main procedure of the program
  # Set the logger, where the program output will be send
  body:
    let logger: ConsoleLogger = newConsoleLogger(
        fmtStr = "[$time] - $levelname: ")
    addHandler(handler = logger)
    setLogFilter(lvl = lvlInfo)
    try:
      info(args = "Starting nimalyzer ver 0.3.0")
    except Exception:
      abortProgram(message = "Can't log messages.")
    # No configuration file specified, quit from the program
    if paramCount() == 0:
      abortProgram(message = "No configuration file specified. Please run the program with path to the config file as an argument.")
    # Read the configuration file and set the program
    {.ruleOff: "varDeclared".}
    let (sources, rules) = parseConfig(configFile = paramStr(i = 1))
    {.ruleOn: "varDeclared".}
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
      var codeParser: Parser = Parser()
      try:
        # Try to convert the source code file to AST
        let fileName: AbsoluteFile = toAbsolute(file = source,
            base = toAbsoluteDir(path = getCurrentDir()))
        try:
          openParser(p = codeParser, filename = fileName,
              inputStream = llStreamOpen(filename = fileName, mode = fmRead),
                  cache = nimCache,
              config = nimConfig)
        except IOError, ValueError, KeyError, Exception:
          abortProgram(message = "Can't open file '" & source &
              "' to parse. Reason: " & getCurrentExceptionMsg())
        try:
          let astNode: PNode = codeParser.parseAll
          codeParser.closeParser
          var currentRule: RuleOptions = RuleOptions(fileName: source)
          # Check the converted source code with each selected rule
          for index, rule in rules.pairs:
            message(text = "Parsing rule [" & $(index + 1) & "/" & $rules.len &
                "]" & (if rule.negation: " negation " else: " ") &
                $rule.ruleType & " rule '" & rule.name & "' with options: '" &
                rule.options.join(sep = ", ") & "'.", level = lvlDebug)
            currentRule.options = rule.options
            currentRule.negation = rule.negation
            currentRule.ruleType = rule.ruleType
            currentRule.amount = (if rule.ruleType ==
                RuleTypes.check: 1 else: 0)
            currentRule.enabled = true
            currentRule.parent = true
            rulesList[rule.index].checkProc(astNode = astNode,
                rule = currentRule)
            if currentRule.amount < 1:
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
