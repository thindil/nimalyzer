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

## The rule to check if all calls in the code uses named parameters
## The syntax in a configuration file is::
##
##   [ruleType] ?not? namedParams
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a call which doesn't have all parameters named.
##   Search type will list all calls which set all their parameters as named
##   and raise error if nothing was found. Count type will simply list the
##   amount of calls which set all their parameters as named.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about calls which have some parameters not named.
##
## Examples
## --------
##
## 1. Check if all calls in module set their parameters as named::
##
##     check namedParams
##
## 2. Search for all calls which don't set their parameters as named::
##
##     search not namedParams

# Standard library imports
import std/logging
# External modules imports
import compiler/[ast, renderer]
import contracts
# Internal modules imports
import ../rules

const ruleName* = "namedparams"

proc ruleCheck*(astTree: PNode; options: RuleOptions): int {.contractual,
    raises: [], tags: [RootEffect].} =
  require:
    astTree != nil
    options.fileName.len > 0
  body:

    proc check(node: PNode; oldResult: var int) {.contractual, raises: [],
        tags: [RootEffect].} =
      require:
        node != nil
      body:
        let messagePrefix = if getLogFilter() < lvlNotice:
            ""
          else:
            options.fileName & ": "
        let callName = try:
              $node[0]
            except KeyError, Exception:
              ""
        if callName.len == 0:
          message(text = "Can't get the name of the call.", level = lvlFatal,
              returnValue = oldResult)
          oldResult.inc
          return
        try:
          for i in 1..<node.sons.len:
            if node[i].kind != nkExprEqExpr:
              if not options.negation:
                if options.ruleType == check:
                  message(text = messagePrefix & "call " & callName &
                      " line: " & $node.info.line &
                      " doesn't have named parameter number: " & $i & "'.",
                      returnValue = oldResult)
              else:
                if options.ruleType == search:
                  message(text = messagePrefix & "call " & callName &
                      " line: " & $node.info.line &
                      " doesn't have named parameter number: " & $i & "'.",
                      returnValue = oldResult, level = lvlNotice,
                      decrease = false)
                elif options.ruleType == RuleTypes.count:
                  oldResult.inc
                break
            else:
              if options.negation:
                if options.ruleType == check:
                  message(text = messagePrefix & "call " & callName &
                      " line: " & $node.info.line &
                      " has named parameter number: " & $i & ".",
                      returnValue = oldResult)
                elif options.ruleType == RuleTypes.count:
                  oldResult.dec
              else:
                if options.ruleType == search:
                  message(text = messagePrefix & "procedure " & callName &
                      " line: " & $node.info.line &
                      " has named parameter number: " & $i & ".",
                      returnValue = oldResult, level = lvlNotice,
                      decrease = false)
                else:
                  oldResult.inc
        except KeyError, Exception:
          message(text = messagePrefix & "can't check parameters of call " &
              callName & " line: " & $node.info.line & ". Reason: " &
              getCurrentExceptionMsg(), returnValue = oldResult)
          oldResult.inc

    result = options.amount
    if astTree.kind == nkCall:
      check(node = astTree, oldResult = result)
      return
    for node in astTree.items:
      for child in node.items:
        result = ruleCheck(astTree = child, options = RuleOptions(
            options: options.options, parent: false,
            fileName: options.fileName, negation: options.negation,
            ruleType: options.ruleType, amount: result))
      if node.kind != nkCall or node.sons.len == 1 or node.sons[1].kind == nkStmtList:
        continue
      check(node = node, oldResult = result)
    if options.parent:
      if options.ruleType == RuleTypes.count:
        if result < 0:
          result = 0
        message(text = (if getLogFilter() <
            lvlNotice: "C" else: options.fileName & ": c") &
            "alls which" & (if options.negation: " not" else: "") &
            " have all named parameters found: " & $result,
                returnValue = result,
            level = lvlNotice)
        return 1
