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
import std/[logging, os, parseopt, strutils]
# External modules imports
import compiler/[idents, llstream, options, parser, pathutils]
import contracts
# Nimalyzer rules imports
import rules/[haspragma, hasentity]

proc main() {.tags: [ReadIOEffect, WriteIOEffect, RootEffect].} =
  # Set the logger, where the program output will be send
  let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
  addHandler(handler = logger)
  setLogFilter(lvl = lvlInfo)
  info("Starting nimalyzer ver 0.1.0")

  proc abortProgram(message: string) {.gcsafe, raises: [], tags: [RootEffect],
      contractual.} =
    require:
      message.len > 0
    body:
      try:
        fatal(message)
        info("Stopping nimalyzer.")
      except Exception:
        echo "Can't log messages"
      quit QuitFailure

  # No configuration file specified, quit from the program
  if paramCount() == 0:
    abortProgram("No configuration file specified. Please run the program with path to the config file as an argument.")
  const rulesNames = [haspragma.ruleName, hasentity.ruleName]
  # Read the configuration file and set the program
  let configFile = paramStr(i = 1)
  type Rule = tuple[name: string; options: seq[string]]
  var
    sources: seq[string]
    rules: seq[Rule]

  proc addFile(fileName: string; sources: var seq[string]) {.gcsafe, raises: [],
      tags: [RootEffect], contractual.} =
    require:
      fileName.len > 0
    body:
      if fileName notin sources:
        sources.add(y = fileName)
        try:
          debug("Added file '" & fileName & "' to the list of files to check.")
        except Exception:
          echo "Can't log message"

  try:
    for line in configFile.lines:
      if line.startsWith(prefix = '#') or line.len == 0:
        continue
      elif line.startsWith(prefix = "verbosity"):
        setLogFilter(lvl = parseEnum[Level](s = line[10..^1]))
        debug("Setting the program verbosity to '" & line[10..^1] & "'.")
      elif line.startsWith(prefix = "output"):
        let fileName = unixToNativePath(line[7..^1])
        addHandler(handler = newFileLogger(filename = fileName,
            fmtStr = "[$time] - $levelname: "))
        debug("Added file '" & fileName & "' as log file.")
      elif line.startsWith(prefix = "source"):
        let fileName = unixToNativePath(line[7..^1])
        addFile(fileName = fileName, sources = sources)
      elif line.startsWith(prefix = "files"):
        for fileName in walkFiles(pattern = line[6..^1]):
          addFile(fileName = fileName, sources = sources)
      elif line.startsWith(prefix = "directory"):
        for fileName in walkDirRec(dir = line[10..^1]):
          addFile(fileName = fileName, sources = sources)
      elif line.startsWith(prefix = "check"):
        var checkRule = initOptParser(cmdline = line)
        checkRule.next
        checkRule.next
        var newRule: Rule = (name: checkRule.key.toLowerAscii, options: @[])
        if newRule.name notin rulesNames:
          abortProgram("No rule named '" & newRule.name & "' available.")
        while true:
          checkRule.next()
          if checkRule.kind == cmdEnd:
            break
          newRule.options.add(y = checkRule.key)
        rules.add(y = newRule)
        debug("Added rule '" & rules[^1].name &
            "' with options: '" & rules[^1].options.join(", ") & "' to the list of rules to check.")
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
  const rulesCalls = [haspragma.ruleCheck, hasentity.ruleCheck]
  var resultCode = QuitSuccess
  # Check source code files with the selected rules
  for i in 0..sources.len - 1:
    info("[" & $(i + 1) & "/" & $sources.len & "] Parsing '" &
        sources[i] & "'")
    var codeParser: Parser
    let fileName = toAbsolute(file = sources[i], base = toAbsoluteDir(
        path = getCurrentDir()))
    openParser(p = codeParser, filename = fileName, llStreamOpen(
        filename = fileName, mode = fmRead), cache = nimCache,
        config = nimConfig)
    let astTree = codeParser.parseAll
    codeParser.closeParser
    for rule in rules:
      if not rulesCalls[rulesNames.find(item = rule.name)](astTree = astTree,
          options = rule.options, parent = true, fileName = sources[i]) and
          resultCode == QuitSuccess:
        resultCode = QuitFailure
  info("Stopping nimalyzer.")
  quit resultCode

when isMainModule:
  main()
