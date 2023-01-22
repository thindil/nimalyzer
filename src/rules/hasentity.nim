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

## The rule to check if the selected procedure has the selected entities, like
## procedures, constants, etc.

# Standard library imports
import std/[logging, strutils]
# External modules imports
import compiler/[ast, renderer]
import contracts
# Internal modules imports
import ../rules

const ruleName* = "hasentity"

proc ruleCheck*(astTree: PNode; options: RuleOptions): bool {.contractual,
    raises: [], tags: [RootEffect].} =
  require:
    astTree != nil
    options.options.len == 2
    options.fileName.len > 0
  body:
    let
      nodeKind = try:
          parseEnum[TNodeKind](s = options.options[0])
        except ValueError:
          nkNone
      childOptions = RuleOptions(options: options.options, parent: false,
          fileName: options.fileName, negation: options.negation,
          ruleType: options.ruleType)
    if nodeKind == nkNone:
      return message(text = "Invalid type of entity: " & options.options[0],
          level = lvlFatal)
    result = false
    for node in astTree.items:
      for child in node.items:
        result = ruleCheck(astTree = child, options = childOptions)
        if result:
          return not options.negation
      if node.kind != nodeKind:
        continue
      try:
        if startsWith(s = $node[0], prefix = options.options[1]):
          if options.negation:
            if options.ruleType == check:
              return message(text = (if getLogFilter() <
                  lvlNotice: "H" else: options.fileName & ": h") &
                  "as declared " & options.options[0] & " with name '" &
                  options.options[1] & "' at line: " & $node.info.line & ".",
                  returnValue = true)
            else:
              return false
          else:
            if options.ruleType == check:
              return true
            else:
              return message(text = (if getLogFilter() <
                  lvlNotice: "H" else: options.fileName & ": h") &
                  "as declared " & options.options[0] & " with name '" &
                  options.options[1] & "' at line: " & $node.info.line & ".",
                  returnValue = true, level = lvlNotice)
      except KeyError:
        continue
      except Exception:
        discard message(text = "Error during checking hasEntity rule: " &
             getCurrentExceptionMsg(), level = lvlFatal)
    if options.parent and not result:
      if options.negation and options.ruleType == check:
        return
      return message(text = (if getLogFilter() <
          lvlNotice: "D" else: options.fileName & ": d") &
          "oesn't have declared " & options.options[0] & " with name '" &
          options.options[1] & "'.", returnValue = (if options.ruleType ==
              check: true else: false), level = (if options.ruleType ==
              check: lvlError else: lvlNotice))
