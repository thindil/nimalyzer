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

## Simple program to get the project's documentation from the default
## configuration file and the project's source code and convert it to the
## project's reStructuredText documentation. The program works only when it is
## started from the main directory of the project

# Standard library imports
import std/[os, strutils]
# External modules imports
import contracts
import ../src/config

proc main() {.contractual, raises: [], tags: [ReadDirEffect, WriteIOEffect,
    ReadIOEffect].} =
  ## The program's main procedure
  body:
    # Check if we are in the main directory of the project
    if not fileExists(filename = "nimalyzer.nimble"):
      quit(errormsg = "Please run the tool from the main directory of the project.")

    proc createHeader(title: string; docFile: File) {.raises: [], tags: [
        WriteIOEffect], contractual.} =
      ## Create the header of the documentation file with its title
      ##
      ## * title   - the title of the documentation which will be written to
      ##             the file
      ## * docFile - the documentation file to which the header will be written
      require:
        title.len > 0
        docFile != nil
      body:
        try:
          docFile.writeLine(x = repeat(c = '=', count = title.len))
          docFile.writeLine(x = title)
          docFile.writeLine(x = repeat(c = '=', count = title.len))
          docFile.writeLine(x = "")
          docFile.writeLine(x = ".. default-role:: code")
          docFile.writeLine(x = ".. contents::")
        except IOError:
          quit(errormsg = "Can't create documentation's header. Reason: " &
              getCurrentExceptionMsg())

    # Open or create a help file for rules to write
    try:
      let rulesFile: File = open(filename = "doc" & DirSep &
          "available_rules.rst", mode = fmWrite)

      # Create the file header
      createHeader(title = "Available rules", docFile = rulesFile)

      # Get the documentation of the program's rules
      for file in walkFiles(pattern = "src/rules/*.nim"):
        var startDoc: bool = false
        let (_, ruleName, _) = splitFile(path = file)
        for line in file.lines:
          if line.startsWith(prefix = "##") and not startDoc:
            startDoc = true
            rulesFile.writeLine(x = "")
            rulesFile.writeLine(x = ruleName.capitalizeAscii & " rule")
            rulesFile.writeLine(x = repeat(c = '=', count = ruleName.len + 5))
            if line.len > 3:
              rulesFile.writeLine(x = line[3..^1])
            else:
              rulesFile.writeLine(x = "")
          elif line.startsWith(prefix = "##"):
            if line.len > 3:
              rulesFile.writeLine(x = line[3..^1])
            else:
              rulesFile.writeLine(x = "")
          elif not line.startsWith(prefix = "##") and startDoc:
            startDoc = false
            break

      # Close the help file for rules
      rulesFile.close
    except IOError:
      quit(errormsg = "Can't create documentation for rules. Reason: " &
          getCurrentExceptionMsg())

    try:
      # Open or create a help file for configuration to write
      let configdocFile: File = open(filename = "doc" & DirSep &
          "configuration.rst", mode = fmWrite)

      # Create the file header
      createHeader(title = "Configuration file syntax", docFile = configdocFile)
      configdocFile.writeLine(x = "")

      # Get the documentation of the program's rules
      let configFile: File = open(filename = "config" & DirSep & "nimalyzer.cfg")
      for line in configFile.lines:
        var newLine: string = line
        newLine.removePrefix(chars = {'#', ' '})
        for prefix in configOptions:
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
