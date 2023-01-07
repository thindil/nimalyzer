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
import std/[logging, os, strutils]
# External modules imports
# Nimalyzer rules imports
import rules/[haspragma]

const availableRules = [haspragma.ruleName]

proc main() =
  # Set the logger, where the program output will be send
  let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
  logger.log(lvlInfo, "Starting nimalyzer ver 0.1.0")
  # No configuration file specified, quit from the program
  if paramCount() == 0:
    logger.log(lvlFatal, "No configuration file specified. Please run the program with path to the config file as an argument.")
    logger.log(lvlInfo, "Stopping nimalyzer.")
    quit QuitFailure
  # Read the configuration file and set the program
  let configFile = paramStr(i = 1)
  var sources, rules: seq[string]
  try:
    for line in configFile.lines:
      if line.startsWith(prefix = '#') or line.len == 0:
        continue
      elif line.startsWith(prefix = "source"):
        sources.add(y = line[7..^1])
        logger.log(lvlDebug, "Added file '" & sources[^1] & "' to the list of files to check.")
      elif line.startsWith(prefix = "check"):
        let ruleName = line[6..line.find(sub = ' ', start = 6) - 1]
        if ruleName.toLowerAscii notin availableRules:
          logger.log(lvlFatal, "No rule named '" & ruleName & "' available.")
          logger.log(lvlInfo, "Stopping nimalyzer.")
          quit QuitFailure
        rules.add(y = ruleName)
  except IOError:
    logger.log(lvlFatal, "The specified configuration file '" & configFile & "' doesn't exist.")
    logger.log(lvlInfo, "Stopping nimalyzer.")
    quit QuitFailure
  # Check if the list of source code files is set
  if sources.len == 0:
    logger.log(lvlFatal, "No files specified to check. Please enter any files names to the configuration file.")
    logger.log(lvlInfo, "Stopping nimalyzer.")
    quit QuitFailure
  # Check if the list of rules is set
  if rules.len == 0:
    logger.log(lvlFatal, "No rules specified to check. Please enter any rule names to the configuration file.")
    logger.log(lvlInfo, "Stopping nimalyzer.")
    quit QuitFailure
  logger.log(lvlInfo, "Stopping nimalyzer.")

when isMainModule:
  main()
