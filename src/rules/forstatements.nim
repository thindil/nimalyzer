# Copyright © 2023 Bartek thindil Jasicki
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

## The rule to check do `for` statements in the code don't contain some
## expressions. At the moment, it can check only if the `for` statement iterator
## has or doesn't have the direct call to `pairs` or `items` iterators.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? forStatements
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a `for` statement which violates the check. Search
##   type will list all statements which violates the check or raise an
##   error if nothing found. Count type will simply list the amount of the
##   statements which violates the check. Fix type will try to fix the code
##   which violates check: it will add the direct call for proper iterator or
##   remove it, for negation type of the rule.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about the `for` statements which not violates the
##   rule's check.
## * forStatements is the name of the rule. It is case-insensitive, thus it can be
##   set as *forstatements*, *forStatements* or *fOrStAtEmEnTs*.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "forStatements"* in the code before it. For
## example, if the rule should be disabled for the selected statement, the full
## declaration of it should be::
##
##     {.ruleOff: "forStatements".}
##     for i in [1..5]:
##       echo i
##
## To enable the rule again, the pragma *ruleOn: "forStatements"* should be
## added in the code before it. For example, if the rule should be re-enabled
## for the statement, the full declaration should be::
##
##     {.ruleOn: "forStatements".}
##     for i in [1..5]:
##       echo i
##
## Examples
## --------
##
## 1. Check if all `for` statements have direct calls for iterators::
##
##     check forStatements
##
## 2. Remove all direct calls for iterators from `for` statements::
##
##     fix not forStatements

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "forstatements",
  ruleFoundMessage = "for statements which can{negation} be upgraded",
  ruleNotFoundMessage = "for statements which can{negation} be upgraded not found.",
  rulePositiveMessage = "for statement, line: {params[0]} {params[1]}",
  ruleNegativeMessage = "for statement, line: {params[0]} {params[1]}")

checkRule:
  initCheck:
    discard
  startCheck:
    let negation: string = (if rule.negation: "'t" else: "")
  checking:
    if node.kind == nkForStmt or (node.kind == nkStmtList and node[0].kind == nkForStmt):
      let nodeToCheck: PNode = (if node.kind == nkForStmt: node else: node[0])
      var
        checkResult: bool = false
        callName: string = ""
      if nodeToCheck[^2].kind == nkCall and (($nodeToCheck[^2]).startsWith(
          prefix = "pairs") or ($nodeToCheck[^2]).startsWith(prefix = "items")):
        checkResult = true
        callName = $nodeToCheck[^2][0]
      elif nodeToCheck[^2].kind == nkDotExpr and (($nodeToCheck[^2]).endsWith(
          suffix = ".pairs") or ($nodeToCheck[^2]).endsWith(suffix = ".items")):
        checkResult = true
        callName = $nodeToCheck[^2][^1]
      if rule.ruleType == RuleTypes.count:
        checkResult = not checkResult
      setResult(checkResult = checkResult, positiveMessage = positiveMessage,
          negativeMessage = negativeMessage, node = nodeToCheck, params = [
          $nodeToCheck.info.line, (if rule.negation: "uses '" & callName &
          "'" else: "don't use 'pairs' or 'items'") & " for iterators."])
  endCheck:
    discard

fixRule:
  # Remove iterators pairs or items from for statement
  if rule.negation:
    if astNode[^2].kind == nkCall:
      astNode[^2] = newIdentNode(ident = getIdent(ic = rule.identsCache,
          identifier = $astNode[^2][^1]), info = astNode[^2][^1].info)
    else:
      astNode[^2] = newIdentNode(ident = getIdent(ic = rule.identsCache,
          identifier = $astNode[^2][0]), info = astNode[^2][0].info)
    return true
  # Add iterators pairs or items from for statement
  astNode[^2] = newTree(kind = nkDotExpr, children = [newIdentNode(
      ident = getIdent(ic = rule.identsCache, identifier = $astNode[^2]),
      info = astNode[^2].info), newIdentNode(ident = getIdent(
      ic = rule.identsCache, identifier = (if astNode.len ==
      4: "pairs" else: "items")), info = astNode[^2].info)])
  return true
