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

## The rule to check do `if` and `when` statements in the code don't contain some
## expressions. Checked things:
##
## * Empty statements. `If` and `when` statements, which contains only `discard` statement.
## * A branch `else` after a finishing statement like `return`, `continue`,
##   `break` or `raise`. Example::
##
##     if a == 1:
##       return
##     else:
##       doSomething()
##
## * A negative condition in `if` and `when` statements with a branch `else`. Example::
##
##     if a != 1:
##       doSomething()
##     else:
##       doSomething2()
##
## * The maximum and minimum amount of `if` and `when` statements' branches. The check
##   must be set explicitly, it isn't performed when option *all* is set.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? ifStatements [checkType] [amount]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a `if` or `when` statement which violates any of the checks. Search
##   type will list all statements which violates any of checks or raise an
##   error if nothing found. Count type will simply list the amount of the
##   statements which violates the checks. Fix type will try to fix the code
##   which violates checks: will remove empty statements, move outside the `if`
##   or `when` block code after finishing statement or replace negative condition in the
##   statement with positive and move the code blocks. Fix type not works with
##   negation.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about the `if` and `when` statements which not violate the checks.
##   Probably useable only with search and count type of rule.
## * ifStatements is the name of the rule. It is case-insensitive, thus it can be
##   set as *ifstatements*, *ifstatements* or *iFsTaTeMeNts*.
## * checkType is the type of checks to perform on the `if` statements. Proper
##   values are: *all*, *negative*, *moveable*, *empty*, *min* and *max*.
##   Setting it to all will perform all rule's checks on statements except for
##   the check for maximum and minimum amount of branches. Negative value will
##   check only if the `if` and `when` statements don't have a negative condition with branch
##   `else`. Moveable value will check only if the content of `else` branch can
##   be moved outside the statement. Empty value will check if the `if` or `when`
##   statements doesn't contain only a `discard` statement. Min value will check
##   if all `if` or `when` statements have at least the selected amount of branches. Max
##   value will check if the `if` or `when` statements have maximum the selected amount of
##   branches.
## * amount parameter is required only for *min* and *max* types of checks and
##   it is ignored for another. It is desired amount of branches for the `if` or `when`
##   statements, minimal or maximum, depends on check's type.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "ifStatements"* in the code before it. For example,
## if the rule should be disabled for the statement, the full declaration of it
## should be::
##
##     {.ruleOff: "ifStatements".}
##     if a == 1:
##       echo a
##
## To enable the rule again, the pragma *ruleOn: "ifStatements"* should be added
## in the code before it. For example, if the rule should be re-enabled for the
## statement, the full declaration should be::
##
##     {.ruleOn: "ifStatements".}
##     if a == 1:
##       echo a
##
## Examples
## --------
##
## 1. Check if all `if` and `when` statements are correct::
##
##     check ifStatements all
##
## 2. Remove all empty `if` and `when` statements::
##
##     fix ifStatements empty
##
## 3. Check if all `if` and `when` statements have at least 3 branches:
##
##     check ifStatements min 3

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "ifstatements",
  ruleFoundMessage = "if statements which can{negation} be upgraded",
  ruleNotFoundMessage = "if statements which can{negation} be upgraded not found.",
  rulePositiveMessage = "if statement, line: {params[0]} {params[1]}",
  ruleNegativeMessage = "if statement, line: {params[0]} {params[1]}",
  ruleOptions = @[custom, integer],
  ruleOptionValues = @["all", "negative", "moveable", "empty", "min", "max"],
  ruleMinOptions = 1)

proc checkMinMax(node, parent: PNode; messagePrefix: string;
    rule: var RuleOptions) {.raises: [ValueError], tags: [RootEffect], contractual.} =
  body:
    let astNode: PNode = parent
    var checkResult: bool = true
    if rule.options[0].toLowerAscii == "min":
      if node.len < rule.options[1].parseInt():
        checkResult = false
    else:
      if node.len > rule.options[1].parseInt():
        checkResult = false
    if rule.ruleType in {RuleTypes.count, search}:
      checkResult = not checkResult
    setResult(checkResult = checkResult,
        positiveMessage = positiveMessage,
        negativeMessage = negativeMessage, node = node,
        ruleData = "amount", params = [$node.info.line,
        "the statement " & (if rule.negation: "doesn't have " else: "has ") &
        (if rule.options[0].toLowerAscii == "max": "more " else: "less ") &
            "than " & rule.options[1] & " branches."])

checkRule:
  initCheck:
    if rule.options[0] in ["min", "max"] and rule.options.len < 2:
      rule.amount = errorMessage(text = "Can't check the amount of branches of if statements, no value for the branches' amount set in the configuration file.")
      return
  startCheck:
    let negation: string = (if rule.negation: "'t" else: "")
  checking:
    if node.kind in {nkIfStmt, nkWhenStmt}:
      var oldAmount: int = rule.amount
      if node.len > 1:
        # Check if the if statement starts with negative condition and has else branch
        if rule.options[0].toLowerAscii in ["all", "negative"]:
          try:
            let conditions: seq[string] = ($node[0]).split
            var checkResult: bool = true
            if (conditions.len > 2 and conditions[2] == "not") or (
                conditions.len > 3 and conditions[3] in ["notin", "!="]):
              checkResult = node[^1].kind notin {nkElse, nkElseExpr}
              if rule.ruleType == RuleTypes.count:
                checkResult = not checkResult
            elif rule.ruleType in {RuleTypes.count, search}:
              checkResult = false
            setResult(checkResult = checkResult,
                positiveMessage = positiveMessage,
                negativeMessage = negativeMessage, node = node,
                ruleData = "negation", params = [$node.info.line,
                (if rule.negation: "doesn't start" else: "starts") &
                " with a negative condition."])
          except Exception as e:
            rule.amount = errorMessage(
                text = "Can't check the if statement.", e = e)
            return
        # Check if the last if branch can be moved outside the if statement
        if rule.options[0].toLowerAscii in ["all", "moveable"] and
            rule.amount == oldAmount:
          let lastNode: PNode = try:
              if node[^2][^1].kind == nkStmtList:
                node[^2][^1][^1]
              else:
                node[^2][^1]
            except:
              node[^2]
          if lastNode.kind in nkLastBlockStmts:
            var checkResult: bool = node[^1].kind notin {nkElse, nkElseExpr}
            if rule.ruleType == RuleTypes.count:
              checkResult = not checkResult
            setResult(checkResult = checkResult,
                positiveMessage = positiveMessage,
                negativeMessage = negativeMessage, node = node,
                ruleData = "outside", params = [$node.info.line,
                "the content of the last branch can" & negation &
                " be moved outside the if statement."])
      # Check if the if statement contains empty branches (with discard only)
      if rule.options[0].toLowerAscii in ["all", "empty"] and rule.amount == oldAmount:
        var checkResult: bool = true
        for child in node:
          if child.kind == nkIdent:
            continue
          if child[^1].kind == nkStmtList and child[^1].len == 1:
            checkResult = child[^1][0].kind != nkDiscardStmt or child[^1][0][
                0].kind != nkEmpty
            if rule.ruleType in {RuleTypes.count, search}:
              checkResult = not checkResult
            setResult(checkResult = checkResult,
                positiveMessage = positiveMessage,
                negativeMessage = negativeMessage, node = node,
                ruleData = "discard", params = [$node.info.line,
                "the statement branch " & (
                if rule.negation: "doesn't contain" else: "contains") &
                " only discard statement."])
            break
        if rule.ruleType == fix and not checkResult:
          return
      # Check the amount of the if statement branches (min and max)
      if rule.options[0].toLowerAscii in ["min", "max"] and rule.amount ==
          oldAmount and node.kind != nkWhenStmt:
        checkMinMax(node = node, parent = parentNode,
            messagePrefix = messagePrefix, rule = rule)
    else:
      for child in node:
        if child.kind in {nkIfStmt, nkElifBranch, nkWhenStmt}:
          var oldAmount: int = rule.amount
          # Check the amount of the if statement branches (min and max)
          if rule.options[0].toLowerAscii in ["min", "max"] and rule.amount ==
              oldAmount and node.kind != nkWhenStmt:
            checkMinMax(node = child, parent = node,
                messagePrefix = messagePrefix, rule = rule)
  endCheck:
    discard

fixRule:
  # Don't change anything if rule has negation or check for amount of branches
  if rule.negation or data == "amount":
    return false
  case data
  # Remove empty if statement
  of "discard":
    for index, child in parentNode:
      if child == astNode:
        parentNode.delSon(idx = index)
        return true
  # Move the part of the if statement outside
  of "outside":
    let
      newIfNode: PNode = newTree(kind = astNode.kind, children = astNode.sons)
      newNode: PNode = newTree(kind = astNode[^1][0].kind, children = astNode[
          ^1][0].sons)
      newParent: PNode = newTree(kind = parentNode.kind, children = [])
    for child in parentNode:
      if child == astNode:
        newIfNode.delSon(idx = astNode.len - 1)
        newParent.add(son = newIfNode)
        newParent.add(son = newNode)
      else:
        newParent.add(son = child)
    parentNode.discardSons
    for child in newParent:
      parentNode.add(son = child)
    return true
  # Replace the negative expression in the if statemet
  of "negation":
    try:
      if $astNode[0][0][0] == "not":
        astNode[0][0][0] = newNode(kind = nkEmpty)
      else:
        astNode[0][0][0] = newIdentNode(ident = getIdent(ic = rule.identsCache,
            identifier = "=="), info = astNode[0][0].info)
    except KeyError, Exception:
      discard errorMessage(text = "Can't replace negative statement in an if expression. Reason: " &
          getCurrentExceptionMsg())
      return false
    let
      negativeNode: PNode = newTree(kind = astNode[0][1].kind,
          children = astNode[0][1].sons)
      positiveNode: PNode = newTree(kind = astNode[^1][0].kind,
          children = astNode[^1][0].sons)
    astNode[0][1] = positiveNode
    astNode[^1][0] = negativeNode
    return true
