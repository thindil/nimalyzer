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

# Standard library imports
import std/[os, strutils]
# External modules imports
import contracts

proc main() {.contractual, raises: [], tags: [ReadDirEffect, WriteIOEffect,
    ReadIOEffect].} =
  body:
    # Check if we are in the main directory of the project
    if not fileExists(filename = "nimalyzer.nimble"):
      quit(errormsg = "Please run the tool from the main directory of the project.")

    # Open or create a help file for rules to write
    try:
      let rulesFile = open(filename = "doc" & DirSep & "rules.rst",
          mode = fmWrite)

      # Create the file header
      rulesFile.writeLine(x = repeat(c = '=', count = 15))
      rulesFile.writeLine(x = "Available rules")
      rulesFile.writeLine(x = repeat(c = '=', count = 15))
      rulesFile.writeLine(x = "")
      rulesFile.writeLine(x = ".. default-role:: code")
      rulesFile.writeLine(x = ".. contents::")

      # Get the documentation of the program's rules
      for file in walkFiles(pattern = "src/rules/*.nim"):
        var startDoc = false
        let (_, ruleName, _) = splitFile(file)
        for line in file.lines:
          if line.startsWith("##") and not startDoc:
            startDoc = true
            rulesFile.writeLine(x = "")
            rulesFile.writeLine(x = ruleName.capitalizeAscii & " rule")
            rulesFile.writeLine(x = repeat(c = '=', count = ruleName.len + 5))
            if line.len > 3:
              rulesFile.writeLine(x = line[3..^1])
            else:
              rulesFile.writeLine(x = "")
          elif line.startsWith("##"):
            if line.len > 3:
              rulesFile.writeLine(x = line[3..^1])
            else:
              rulesFile.writeLine(x = "")
          elif not line.startsWith("##") and startDoc:
            startDoc = false
            break

      # Close the help file for rules
      rulesFile.close
    except IOError:
      quit(errormsg = "Can't create documentation for rules. Reason: " &
          getCurrentExceptionMsg())

    try:
      # Open or create a help file for configuration to write
      let configdocFile = open(filename = "doc" & DirSep & "config.rst",
          mode = fmWrite)

      # Create the file header
      configdocFile.writeLine(x = repeat(c = '=', count = 25))
      configdocFile.writeLine(x = "Configuration file syntax")
      configdocFile.writeLine(x = repeat(c = '=', count = 25))
      configdocFile.writeLine(x = "")
      configdocFile.writeLine(x = ".. default-role:: code")
      configdocFile.writeLine(x = ".. contents::")
      configdocFile.writeLine(x = "")

      # Get the documentation of the program's rules
      let configFile = open(filename = "config" & DirSep & "nimalyzer.cfg")
      const settings = ["verbosity", "output", "source", "files", "directory",
          "check", "search", "count"]
      for line in configFile.lines:
        var newLine = line
        newLine.removePrefix(chars = {'#', ' '})
        for prefix in settings:
          if newLine.startsWith(prefix = prefix):
            newLine = newLine.indent(count = 4)
        configdocFile.writeLine(x = newLine)

      # Close the help file for rules
      configdocFile.close
    except IOError:
      quit(errormsg = "Can't create documentation for configuration file. Reason: " &
          getCurrentExceptionMsg())

when isMainModule:
  main()
