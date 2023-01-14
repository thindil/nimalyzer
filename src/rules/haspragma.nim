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

## The rule to check if the selected procedure has the selected pragma

# Standard library imports
import std/[logging, strutils]
# External modules imports
import compiler/[ast, renderer]

const ruleName* = "haspragma"

proc ruleCheck*(astTree: PNode; options: seq[string];
    logger: ConsoleLogger, parent: bool): bool =
  if parent:
    result = true
  for node in astTree.items:
    for child in node.items:
      result = ruleCheck(astTree = child, options = options,
          logger = logger, parent = false)
    if node.kind notin routineDefs:
      continue
    let pragmas = getDeclPragma(n = node)
    if pragmas == nil:
      error("procedure " & $node[0] & " line: " &
          $node.info.line & " doesn't have declared any pragmas.")
      result = false
      continue
    var strPragmas: seq[string]
    for pragma in pragmas:
      strPragmas.add(y = $pragma)
    for pragma in options:
      if '*' notin [pragma[0], pragma[^1]] and pragma notin strPragmas:
        error("procedure " & $node[0] & " line: " &
            $node.info.line & " doesn't have declared pragma: " & pragma & ".")
        result = false
      elif pragma[^1] == '*' and pragma[0] != '*':
        var hasPragma = false
        for procPragma in strPragmas:
          if procPragma.startsWith(prefix = pragma[0..^2]):
            hasPragma = true
            break
        if not hasPragma:
          error("procedure " & $node[0] & " line: " &
              $node.info.line & " doesn't have declared pragma: " & pragma & ".")
          result = false
      elif pragma[0] == '*' and pragma[^1] != '*':
        var hasPragma = false
        for procPragma in strPragmas:
          if procPragma.endsWith(suffix = pragma[1..^1]):
            hasPragma = true
            break
        if not hasPragma:
          error("procedure " & $node[0] & " line: " &
              $node.info.line & " doesn't have declared pragma: " & pragma & ".")
          result = false
      elif '*' in [pragma[0], pragma[^1]]:
        var hasPragma = false
        for procPragma in strPragmas:
          if procPragma.contains(sub = pragma[1..^2]):
            hasPragma = true
            break
        if not hasPragma:
          error("procedure " & $node[0] & " line: " &
              $node.info.line & " doesn't have declared pragma with value: " &
                  pragma & ".")
          result = false
