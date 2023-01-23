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
import contracts
# Internal modules imports
import ../rules

const ruleName* = "haspragma"

proc ruleCheck*(astTree: PNode; options: RuleOptions): int {.contractual,
    raises: [], tags: [RootEffect].} =
  require:
    astTree != nil
    options.options.len > 0
    options.fileName.len > 0
  body:
    result = 1
    let messagePrefix = if getLogFilter() < lvlNotice:
        ""
      else:
        options.fileName & ": "

    proc setResult(procName, line, pragma: string; hasPragma: bool;
        oldResult: int): int {.raises: [], tags: [RootEffect], contractual.} =
      require:
        procName.len > 0
        line.len > 0
        pragma.len > 0
      body:
        if not hasPragma:
          if options.negation and options.ruleType == check:
            return if oldResult == 0: oldResult else: 1
          if options.ruleType == check:
            return message(text = messagePrefix & "procedure " & procName &
                " line: " & line & " doesn't have declared pragma: " & pragma &
                ".")
          else:
            if options.negation:
              return message(text = messagePrefix & "procedure " & procName &
                  " line: " & line & " doesn't have declared pragma: " & pragma &
                  ".", returnValue = 1, level = lvlNotice)
            return 0
        else:
          if options.negation:
            if options.ruleType == check:
              return message(text = messagePrefix & "procedure " & procName & " line: " &
                    line & " has declared pragma: " & pragma & ".")
            else:
              return 0
          if options.ruleType == search:
            return message(text = messagePrefix & "procedure " & procName & " line: " &
                  line & " has declared pragma: " & pragma & ".",
                  returnValue = 1, level = lvlNotice)
          return if oldResult == 0: oldResult else: 1

    for node in astTree.items:
      for child in node.items:
        result = ruleCheck(astTree = child, options = RuleOptions(
            options: options.options, parent: false,
            fileName: options.fileName, negation: options.negation,
            ruleType: options.ruleType))
      if node.kind notin routineDefs:
        continue
      let
        pragmas = getDeclPragma(n = node)
        procName = try:
            $node[0]
          except KeyError, Exception:
            ""
      if procName.len == 0:
        return message(text = "Can't get the name of the procedure.",
            level = lvlFatal)
      if pragmas == nil:
        if not options.negation:
          if options.ruleType == check:
            result = message(messagePrefix & "procedure " & procName & " line: " &
                  $node.info.line & " doesn't have declared any pragmas.")
          else:
            result = 0
        else:
          if options.ruleType == search:
            result = message(messagePrefix & "procedure " & procName & " line: " &
                  $node.info.line & " doesn't have declared any pragmas.",
                  returnValue = 1, level = lvlNotice)
          else:
            result = 1
        continue
      var strPragmas: seq[string]
      for pragma in pragmas:
        try:
          strPragmas.add(y = $pragma)
        except KeyError, Exception:
          discard
      for pragma in options.options:
        if '*' notin [pragma[0], pragma[^1]] and pragma notin strPragmas:
          result = setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = false, oldResult = result)
        elif pragma[^1] == '*' and pragma[0] != '*':
          var hasPragma = false
          for procPragma in strPragmas:
            if procPragma.startsWith(prefix = pragma[0..^2]):
              hasPragma = true
              break
          result = setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = hasPragma, oldResult = result)
        elif pragma[0] == '*' and pragma[^1] != '*':
          var hasPragma = false
          for procPragma in strPragmas:
            if procPragma.endsWith(suffix = pragma[1..^1]):
              hasPragma = true
              break
          result = setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = hasPragma, oldResult = result)
        elif '*' in [pragma[0], pragma[^1]]:
          var hasPragma = false
          for procPragma in strPragmas:
            if procPragma.contains(sub = pragma[1..^2]):
              hasPragma = true
              break
          result = setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = hasPragma, oldResult = result)
        else:
          result = setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = true, oldResult = result)
    if options.parent and result == 0 and options.ruleType == search:
      return message(text = "The selected pragma(s) not found.")
