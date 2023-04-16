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

proc main() {.contractual, raises: [], tags: [ReadDirEffect, ReadIOEffect,
    WriteIOEffect].} =
  ## The program's main procedure
  body:
    # Check if we are in the main directory of the project
    if not fileExists(filename = "nimalyzer.nimble"):
      quit(errormsg = "Please run the tool from the main directory of the project.")
    # Check if the user entered the name of the rule to create
    if paramCount() == 0:
      quit(errormsg = "Please enter the name of the rule to create")
    let
      fileName = "src" & DirSep & "rules" & DirSep & paramStr(
          i = 1).toLowerAscii & ".nim"
      author = (if paramCount() == 1: "Bartek thindil Jasicki" else: paramStr(i = 2))
    if fileExists(filename = fileName):
      quit(errormsg = "The rule with name '" & paramStr(i = 1) & "' exists.")
    # Copy the template rule file to the proper directory
    try:
      var ruleCode = readFile(filename = "tools" & DirSep & "rule.txt")
      ruleCode = ruleCode.replace(sub = "--author--", by = author)
      ruleCode = ruleCode.replace(sub = "--ruleName--", by = paramStr(i = 1))
      ruleCode = ruleCode.replace(sub = "--rulename--", by = paramStr(
          i = 1).toLowerAscii)
      writeFile(filename = fileName, content = ruleCode)
    except IOError:
      quit(errormsg = "Can't create rule '" & paramStr(i = 1) & "'. Reason: " &
          getCurrentExceptionMsg())

when isMainModule:
  main()
