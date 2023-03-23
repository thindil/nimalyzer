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

## Provides code for parse the program's configuration file

# Standard library imports
import std/[os, parseopt, tables]
# Internal modules imports
import rules, utils

type RuleData* = object ## Contains information about the configuration of the program's rule
  name*: string        ## The name of the rule
  options*: seq[string] ## The options list provided by the user in a configuration file
  negation*: bool      ## If true, the rule is negation
  ruleType*: RuleTypes ## The type of the rule

proc parseConfig*(configFile: string): tuple[sources: seq[string], rules: seq[
    RuleData]] {.sideEffect, raises: [], tags: [ReadIOEffect, RootEffect],
    contractual.} =
  require:
    configFile.len > 0
  body:

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
          let fileName: string = unixToNativePath(path = line[7..^1])
          addHandler(handler = newFileLogger(filename = fileName,
              fmtStr = "[$time] - $levelname: "))
          message(text = "Added file '" & fileName & "' as log file.",
              level = lvlDebug)
        # Set the source code file to check
        elif line.startsWith(prefix = "source"):
          let fileName: string = unixToNativePath(path = line[7..^1])
          addFile(fileName = fileName, sources = result.sources)
        # Set the source code files to check
        elif line.startsWith(prefix = "files"):
          try:
            for fileName in walkFiles(pattern = line[6..^1]):
              addFile(fileName = fileName, sources = result.sources)
          except OSError:
            abortProgram(message = "Can't parse setting: '" & line &
                "'. Reason: ", e = getCurrentException())
        # Set the source code files to check, the second option
        elif line.startsWith(prefix = "directory"):
          try:
            for fileName in walkDirRec(dir = line[10..^1]):
              addFile(fileName = fileName, sources = result.sources)
          except OSError:
            abortProgram(message = "Can't add files to check. Reason: ",
                e = getCurrentException())
        # Set the program's rule to test the code
        elif line.startsWith(prefix = "check") or line.startsWith(
            prefix = "search") or line.startsWith(prefix = "count"):
          var configRule: OptParser = initOptParser(cmdline = line)
          configRule.next
          let ruleType: RuleTypes = try:
              parseEnum[RuleTypes](s = configRule.key)
            except ValueError:
              none
          if ruleType == none:
            abortProgram(message = "Unknown type of rule: '" & configRule.key & "'.")
          configRule.next
          var newRule: RuleData = RuleData(name: configRule.key.toLowerAscii,
              options: @[], negation: false, ruleType: ruleType)
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
          result.rules.add(y = newRule)
          message(text = "Added" & (if result.rules[
              ^1].negation: " negation " else: " ") & $result.rules[
              ^1].ruleType & " rule '" & result.rules[^1].name &
              "' with options: '" & result.rules[^1].options.join(", ") &
              "' to the list of rules to check.", level = lvlDebug)
    except IOError:
      abortProgram(message = "The specified configuration file '" & configFile & "' doesn't exist.")
