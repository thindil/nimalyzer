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
import std/[os, strutils, terminal]
# External modules imports
import contracts

proc main() {.contractual, raises: [], tags: [ReadDirEffect, ReadIOEffect,
    WriteIOEffect].} =
  ## The program's main procedure
  body:
    # Check if we are in the main directory of the project
    if not fileExists(filename = "nimalyzer.nimble"):
      quit(errormsg = "Please run the tool from the main directory of the project.")
    try:
      # Ask the user for the new rule parameters
      echo "The name of the new rule: "
      var name: string = ""
      while name.len == 0:
        name = stdin.readLine
      echo "The rule will be built-in or external? (b/e):"
      var
        builtIn: bool = true
        ruleType: char = 'a'
      while true:
        ruleType = getch()
        if ruleType in {'b', 'B'}:
          break
        elif ruleType in {'e', 'E'}:
          builtIn = false
          break
      var path: string = ""
      if not builtIn:
        echo "The path where the rule directory will be created: "
        while path.len == 0:
          path = stdin.readLine
      else:
        path = "src/rules"
      echo "The author of the rule, leave empty for use default value: "
      var author: string = stdin.readLine
      if author.len == 0:
        author = "Bartek thindil Jasicki"
      let fileName: string = path & DirSep & name.toLowerAscii & ".nim"
      # Check if a rule with the same name exists
      if fileExists(filename = fileName):
        quit(errormsg = "The rule with name '" & name & "' exists.")
      # Create directory for the external rule
      if not builtIn:
        createDir(dir = path)
      # Copy the template rule file to the proper directory
      var ruleCode: string = readFile(filename = "tools" & DirSep & "rule.txt")
      ruleCode = ruleCode.replace(sub = "--author--", by = author)
      ruleCode = ruleCode.replace(sub = "--ruleName--", by = name)
      ruleCode = ruleCode.replace(sub = "--rulename--", by = name.toLowerAscii)
      # Replace path to rules module for the external rule
      if not builtIn:
        let dirDepth: int = path.count(sub = DirSep) + 1
        ruleCode = ruleCode.replace(sub = "..", by = "../".repeat(
            n = dirDepth) & "src")
      writeFile(filename = fileName, content = ruleCode)
      if builtIn:
        echo "The program's rule '" & name & "' created in file '" & fileName &
          "'. Don't forget to update the file src/utils.nim either."
      else:
        echo "The program's rule '" & name & "' created in directory '" & path &
          "'."
    except IOError, OSError:
      quit(errormsg = "Can't create the new rule. Reason: " &
          getCurrentExceptionMsg())

when isMainModule:
  main()
