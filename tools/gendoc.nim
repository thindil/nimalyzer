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

import std/[os, strutils]

proc main() =
  # Check if we are in the main directory of the project
  if not fileExists(filename = "nimalyzer.nimble"):
    quit(errormsg = "Please run the tool from the main directory of the project.")

  # Create documentation directory if not exists
  createDir(dir = "docs")

  # Open or create a help file for rule to write
  let rulesFile = open(filename = "docs" & DirSep & "rules.rst", mode = fmWrite)

  # Create the file header
  rulesFile.writeLine(x = repeat(c = '=', count = 20))
  rulesFile.writeLine(x = "Nimalyzer rules info")
  rulesFile.writeLine(x = repeat(c = '=', count = 20))
  rulesFile.writeLine(x = "")
  rulesFile.writeLine(x = ".. default-role:: code")
  rulesFile.writeLine(x = ".. contents::")

  # Get the documentation of the program's rules
  for file in walkFiles(pattern = "src/rules/*.nim"):
    var
      startDoc = false
    for line in file.lines:
      if line.startsWith("##") and not startDoc:
        startDoc = true
        rulesFile.writeLine(x = line[2..^1].strip)
      elif line.startsWith("##"):
        rulesFile.writeLine(x = line[2..^1].strip)
      elif not line.startsWith("##") and startDoc:
        startDoc = false
        rulesFile.writeLine(x = "")
        rulesFile.writeLine(x = repeat(c = '-', count = 5))
        rulesFile.writeLine(x = "")
        break

  # Close the help file for rules
  rulesFile.close

when isMainModule:
  main()
