# Copyright © 2023-2024 Bartek thindil Jasicki
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

## The rule to check do `for` statements in the code contains or not some
## expressions. Checked things:
##
## * Empty statements. `For` statements, which contains only `discard` statement.
## * Do `for` statements explicitly calls iterators `pairs` or `items`.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? forStatements [checkType]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a `for` statement which violates the check. Search
##   type will list all statements which violates the check or raise an
##   error if nothing found. Count type will simply list the amount of the
##   statements which violates the check. Fix type will try to fix the code
##   which violates check. The negation of fix type doesn't work with checkType
##   set to "empty".
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about the `for` statements which not violates the
##   rule's check.
## * forStatements is the name of the rule. It is case-insensitive, thus it can be
##   set as *forstatements*, *forStatements* or *fOrStAtEmEnTs*.
## * checkType is the type of checks to perform on the `for` statements. Proper
##   values are: *all*, *iterators*, *empty*. Setting it to all will perform
##   all rule's checks on statements. Iterators value will check only if the
##   `for` statements use `pairs` and `items` iterators. Empty value will check
##   if the `for` statements doesn't contain only a `discard` statement.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "forStatements"* in the code before it. For
## example, if the rule should be disabled for the selected statement, the full
## declaration of it should be::
##
##     {.ruleOff: "forStatements".}
##     for i in 1 .. 5:
##       echo i
##
## To enable the rule again, the pragma *ruleOn: "forStatements"* should be
## added in the code before it. For example, if the rule should be re-enabled
## for the statement, the full declaration should be::
##
##     {.ruleOn: "forStatements".}
##     for i in 1 .. 5:
##       echo i
##
## Examples
## --------
##
## 1. Check if all `for` statements have direct calls for iterators::
##
##     check forStatements iterators
##
## 2. Remove all empty `for` statements::
##
##     fix not forStatements empty

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "forstatements",
  ruleFoundMessage = "for statements which can{negation} be upgraded",
  ruleNotFoundMessage = "for statements which can{negation} be upgraded not found.",
  rulePositiveMessage = "for statement, line: {params[0]} {params[1]}",
  ruleNegativeMessage = "for statement, line: {params[0]} {params[1]}",
  ruleOptions = @[custom],
  ruleOptionValues = @["all", "iterators", "empty"],
  ruleMinOptions = 1)

proc checkIterators(nodeToCheck: PNode; message, checkType: var string;
    checkResult: var bool; rule: var RuleOptions) {.raises: [], tags: [
    RootEffect], contractual.} =
  ## Check for statement do it use iterators pairs or items
  ##
  ## * nodeToCheck - the node which will be checked
  ## * message     - the message shown to the user with result of the check
  ## * checkType   - the name of the check's type
  ## * checkResult - the result of the check
  ## * rule        - the rule options set by the user
  ##
  ## Returns modified arguments checkType, checkResult and rule
  body:
    var callName: string = ""
    try:
      if nodeToCheck[^2].kind == nkCall:
        callName = $nodeToCheck[^2][0]
        if ($nodeToCheck[^2]).startsWith(prefix = "pairs") or ($nodeToCheck[
            ^2]).startsWith(prefix = "items"):
          checkResult = true
      elif nodeToCheck[^2].kind == nkDotExpr:
        callName = $nodeToCheck[^2][^1]
        if ($nodeToCheck[^2]).endsWith(suffix = ".pairs") or ($nodeToCheck[
            ^2]).endsWith(suffix = ".items"):
          checkResult = true
    except Exception as e:
      rule.amount = errorMessage(
          text = "Can't check the for statement.", e = e)
      return
    message = (if rule.negation: "uses '" & callName &
        "'" else: "don't use 'pairs' or 'items'") & " for iterators."
    checkType = "iterator"

proc checkEmpty(nodeToCheck: PNode; message, checkType: var string;
    checkResult: var bool; rule: var RuleOptions) {.raises: [], tags: [
    RootEffect], contractual.} =
  ## Check for statement do it contains only discard statement
  ##
  ## * nodeToCheck - the node which will be checked
  ## * message     - the message shown to the user with result of the check
  ## * checkType   - the name of the check's type
  ## * checkResult - the result of the check
  ## * rule        - the rule options set by the user
  ##
  ## Returns modified arguments checkType, checkResult and rule
  body:
    message = (if rule.negation: "doesn't contain" else: "contains") & " only discard statement."
    checkType = "empty"
    checkResult = nodeToCheck[^1][0].kind != nkDiscardStmt or nodeToCheck[
        ^1][0][0].kind != nkEmpty

checkRule:
  initCheck:
    discard
  startCheck:
    let negation: string = (if rule.negation: "'t" else: "")
  checking:
    if node.kind == nkForStmt or (node.kind == nkStmtList and node[0].kind == nkForStmt):
      let
        nodeToCheck: PNode = (if node.kind == nkForStmt: node else: node[0])
      var
        checkResult: bool = false
        message, checkType: string = ""
      # Check if the for statement uses iterators pairs and items
      if rule.options[0].toLowerAscii in ["all", "iterators"]:
        checkIterators(nodeToCheck = nodeToCheck,
            message = message, checkType = checkType, checkResult = checkResult, rule = rule)
      # Check if the for statement contains only discard statement
      if not checkResult and rule.options[0].toLowerAscii in ["all", "empty"]:
        checkEmpty(nodeToCheck = nodeToCheck, message = message,
            checkType = checkType, checkResult = checkResult, rule = rule)
      if rule.ruleType in {RuleTypes.count, search}:
        checkResult = not checkResult
      let oldAmount: int = rule.amount
      setResult(checkResult = checkResult, positiveMessage = positiveMessage,
          negativeMessage = negativeMessage, ruleData = checkType,
          node = nodeToCheck, params = [ $nodeToCheck.info.line, message])
      # To show the rule's explaination the rule.amount must be negative
      if rule.negation and oldAmount > rule.amount and rule.ruleType == check:
        rule.amount = -1_000
      if rule.ruleType == fix and not checkResult:
        return
    else:
      for child in node:
        setRuleState(node = child, ruleName = ruleSettings.name,
            oldState = rule.enabled)
        if not rule.enabled:
          continue
        if child.kind == nkForStmt or (child.kind == nkStmtList and child[
            0].kind == nkForStmt):
          let
            nodeToCheck: PNode = (if child.kind == nkForStmt: child else: child[0])
          var
            checkResult: bool = false
            message, checkType: string = ""
          # Check if the for statement uses iterators pairs and items
          if rule.options[0].toLowerAscii in ["all", "iterators"]:
            checkIterators(nodeToCheck = nodeToCheck,
                message = message, checkType = checkType,
                checkResult = checkResult, rule = rule)
          # Check if the for statement contains only discard statement
          if not checkResult and rule.options[0].toLowerAscii in ["all", "empty"]:
            checkEmpty(nodeToCheck = nodeToCheck, message = message,
                checkType = checkType, checkResult = checkResult, rule = rule)
          if rule.ruleType in {RuleTypes.count, search}:
            checkResult = not checkResult
          let oldAmount: int = rule.amount
          setResult(checkResult = checkResult,
              positiveMessage = positiveMessage,
              negativeMessage = negativeMessage,
              ruleData = checkType,
              node = nodeToCheck, params = [ $nodeToCheck.info.line, message])
          # To show the rule's explaination the rule.amount must be negative
          if rule.negation and oldAmount > rule.amount and rule.ruleType == check:
            rule.amount = -1_000
          if rule.ruleType == fix and not checkResult:
            return
  endCheck:
    discard

fixRule:
  if data == "iterator":
    # Remove iterators pairs or items from for statement
    if rule.negation:
      try:
        if astNode[^2].kind == nkCall:
          astNode[^2] = newIdentNode(ident = getIdent(ic = rule.identsCache,
              identifier = $astNode[^2][^1]), info = astNode[^2][^1].info)
        else:
          astNode[^2] = newIdentNode(ident = getIdent(ic = rule.identsCache,
              identifier = $astNode[^2][0]), info = astNode[^2][0].info)
        return true
      except Exception:
        discard errorMessage(text = "Can't remove iterators from for statement. Reason: " &
            getCurrentExceptionMsg())
        return false
    # Add iterators pairs or items from for statement
    try:
      astNode[^2] = newTree(kind = nkDotExpr, children = [newIdentNode(
          ident = getIdent(ic = rule.identsCache, identifier = $astNode[^2]),
          info = astNode[^2].info), newIdentNode(ident = getIdent(
          ic = rule.identsCache, identifier = (if astNode.len ==
          4: "pairs" else: "items")), info = astNode[^2].info)])
      return true
    except KeyError, Exception:
      discard errorMessage(text = "Can't add iterator from for statement. Reason: " &
          getCurrentExceptionMsg())
      return false
  else:
    if rule.negation:
      return false
    # Remove empty if statement
    for index, child in parentNode:
      if child == astNode:
        parentNode.delSon(idx = index)
        return true
