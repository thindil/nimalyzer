# Copyright © 2023 Bartek Jasicki <thindil@laeran.pl>
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
# Nimalyzer rules imports
import rules/[haspragma]

proc abortProgram(logger: ConsoleLogger; message: string) =
  logger.log(lvlFatal, message)
  logger.log(lvlInfo, "Stopping nimalyzer.")
  quit QuitFailure

proc main() =
  # Set the logger, where the program output will be send
  let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
  logger.log(lvlInfo, "Starting nimalyzer ver 0.1.0")
  # No configuration file specified, quit from the program
  if paramCount() == 0:
    abortProgram(logger, "No configuration file specified. Please run the program with path to the config file as an argument.")
  const availableRules = [haspragma.ruleName]
  # Read the configuration file and set the program
  let configFile = paramStr(i = 1)
  type Rule = tuple[name: string; options: string]
  var
    sources: seq[string]
    rules: seq[Rule]
  try:
    for line in configFile.lines:
      if line.startsWith(prefix = '#') or line.len == 0:
        continue
      elif line.startsWith(prefix = "source"):
        sources.add(y = unixToNativePath(line[7..^1]))
        logger.log(lvlDebug, "Added file '" & sources[^1] & "' to the list of files to check.")
      elif line.startsWith(prefix = "check"):
        var checkRule = initOptParser(cmdline = line)
        checkRule.next
        checkRule.next
        let ruleName = checkRule.key.toLowerAscii
        if ruleName notin availableRules:
          abortProgram(logger, "No rule named '" & ruleName & "' available.")
        rules.add(y = (name: ruleName, options: checkRule.cmdLineRest))
  except IOError:
    abortProgram(logger, "The specified configuration file '" & configFile & "' doesn't exist.")
  # Check if the lists of source code files and rules is set
  if sources.len == 0:
    abortProgram(logger, "No files specified to check. Please enter any files names to the configuration file.")
  if rules.len == 0:
    abortProgram(logger, "No rules specified to check. Please enter any rule configuration to the configuration file.")
  logger.log(lvlInfo, "Stopping nimalyzer.")

when isMainModule:
  main()
