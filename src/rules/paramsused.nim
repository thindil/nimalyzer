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

## The rule to check if the selected procedure uses all its parameter
## The syntax in a configuration file is::
##
##   [ruleType] ?not? parametersUsed
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a procedure which doesn't use all its parameters.
##   Search type will list all procedures which uses their all parameters and
##   raise error if nothing was found. Count type will simply list the amount
##   of procedures which uses all their parameters.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about procedures which have all parameters used.
##   Probably useable only with search and count type of rule.
##
## Examples
## --------
##
## 1. Check if all procedures in module uses their parameters::
##
##     check parametersUsed
##
## 2. Search for all procedures which don't use their all parameters::
##
##     search not parametersUsed

# Standard library imports
import std/[logging, strutils]
# External modules imports
import compiler/[ast, renderer]
import contracts
# Internal modules imports
import ../rules

const ruleName* = "paramsused"

proc ruleCheck*(astTree: PNode; options: RuleOptions): int {.contractual,
    raises: [], tags: [RootEffect].} =
  require:
    astTree != nil
    options.fileName.len > 0
  body:
    result = options.amount
    let messagePrefix = if getLogFilter() < lvlNotice:
        ""
      else:
        options.fileName & ": "
    for node in astTree.items:
      for child in node.items:
        result = ruleCheck(astTree = child, options = RuleOptions(
            options: options.options, parent: false,
            fileName: options.fileName, negation: options.negation,
            ruleType: options.ruleType, amount: result))
      if node.kind notin routineDefs:
        continue
      let procName = try:
            $node[0]
          except KeyError, Exception:
            ""
      if procName.len == 0:
        message(text = "Can't get the name of the procedure.", level = lvlFatal,
            returnValue = result)
        result.inc
        return
      # No parameters, skip
      if node[3].len < 2:
        continue
      for child in node[3]:
        if child.kind == nkEmpty:
          continue
        var index = -1
        for i in 0..child.len - 3:
          try:
            index = find(s = $node[6], sub = $child[i])
            if index == -1:
              if options.ruleType == check and not options.negation:
                message(messagePrefix & "procedure " & procName & " line: " &
                  $node.info.line & " doesn't use parameter '" & $child[i] & "'.",
                  returnValue = result)
              if options.ruleType == RuleTypes.count and options.negation:
                result.inc
                break
          except KeyError, Exception:
            echo getCurrentExceptionMsg()
    return 1
