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

const ruleName* = "hasentity"

proc ruleCheck*(astTree: PNode; options: seq[string]; parent: bool;
    fileName: string): bool {.contractual, raises: [], tags: [RootEffect].} =
  require:
    astTree != nil
    options.len == 2
    fileName.len > 0
  body:
    let nodeKind = try:
        parseEnum[TNodeKind](s = options[0])
      except ValueError:
        nkNone
    if nodeKind == nkNone:
      try:
        fatal("Invalid type of entity: " & options[0])
      except Exception:
        echo "Can't log message."
      return false
    result = false
    for node in astTree.items:
      for child in node.items:
        result = ruleCheck(astTree = child, options = options, parent = false,
            fileName = fileName)
        if result:
          return
      if node.kind != nodeKind:
        continue
      try:
        if startsWith(s = $node[0], prefix = options[1]):
          return true
      except KeyError:
        continue
      except Exception:
        try:
          fatal("Error during checking hasEntity rule: " & getCurrentExceptionMsg())
        except Exception:
          echo "Can't log message."
    if parent:
      try:
        error((if getLogFilter() < lvlNotice: "D" else: fileName & ": d") &
            "oesn't have declared " & options[0] & " with name '" & options[1] & "'.")
      except Exception:
        echo "Can't log message."
