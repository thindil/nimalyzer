# Copyright © 2024 Bartek thindil Jasicki
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

## The rule to check do `try` statements in the code contains or not some
## expressions. Checked things:
##
## * Except branches do they don't have specified an exception.
## * Except branches for the selected exception.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? trystatements [checkType] [exceptionName]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a `for` statement which violates the check. Search
##   type will list all statements which violates the check or raise an
##   error if nothing found. Count type will simply list the amount of the
##   statements which violates the check. --Insert description
##   how fix type works with the rule--.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about  the `try` statements which not violates the
##   rule's check.
## * trystatements is the name of the rule. It is case-insensitive, thus it can be
##   set as *trystatements*, *trystatements* or *tRyStAtEmEnTs*.
## * checkType is the type of checks to perform on the `try` statements. Proper
##   values are: *empty*, *name*. Setting it to empty will check existence of
##   except branches without specified an exception. Name value will check do
##   exist except branches with the selected exception.
## * exceptionName is required only when checkType is set to *name*. It is the
##   name of the exception to looking for. The argument is case-insensitive,
##   thus setting it to ioerror will find branches with IOError or ioError too.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "tryStatements"* in the code before it. For
## example, if the rule should be disabled for the selected statement, the full
## declaration of it should be::
##
##     {.ruleOff: "tryStatements".}
##     try:
##       someProcedure()
##     except:
##       discard
##
## To enable the rule again, the pragma *ruleOn: "tryStatements"* should be
## added in the code before it. For example, if the rule should be re-enabled
## for the statement, the full declaration should be::
##
##     {.ruleOn: "tryStatements".}
##     try:
##       someProcedure()
##     except IOError:
##       discard
##
## Examples
## --------
##
## 1. Check if all `try` statements have defined exceptions to catch::
##
##     check tryStatements empty
##
## 2. Remove all occurences of `Exception` excetion from `try` statements::
##
##     fix not tryStatements name Exception

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "trystatements",
  ruleFoundMessage = "try statements which can{negation} be upgraded",
  ruleNotFoundMessage = "try statements which can{negation} be upgraded not found.",
  rulePositiveMessage = "try statement, line: {params[0]} {params[1]}",
  ruleNegativeMessage = "try statement, line: {params[0]} {params[1]}",
  ruleOptions = @[custom, str],
  ruleOptionValues = @["empty", "name"],
  ruleMinOptions = 1)

proc checkEmpty(exceptNode: PNode; message, checkType: var string;
    checkResult: var bool; rule: var RuleOptions) {.raises: [], tags: [
    RootEffect], contractual.} =
  ## Check except branch of the try statement do it not specify an exception
  ##
  ## * nodeToCheck - the node which will be checked
  ## * message     - the message shown to the user with result of the check
  ## * checkType   - the name of the check's type
  ## * checkResult - the result of the check
  ## * rule        - the rule options set by the user
  ##
  ## Returns modified arguments checkType, checkResult and rule
  require:
    exceptNode != nil
  body:
    message = (if rule.negation: "doesn't contain" else: "contains") & " general except statement."
    checkType = "empty"
    checkResult = false
    for child in exceptNode:
      if child.kind == nkIdent:
        checkResult = true
        break

proc checkName(exceptNode: PNode; message, checkType: var string;
    checkResult: var bool; rule: var RuleOptions) {.raises: [], tags: [
    RootEffect], contractual.} =
  ## Check except branch of the try statement do it contains the selected
  ## exception
  ##
  ## * nodeToCheck - the node which will be checked
  ## * message     - the message shown to the user with result of the check
  ## * checkType   - the name of the check's type
  ## * checkResult - the result of the check
  ## * rule        - the rule options set by the user
  ##
  ## Returns modified arguments checkType, checkResult and rule
  require:
    exceptNode != nil
  body:
    message = (if rule.negation: "doesn't contain" else: "contains") &
        " except statement with rule '" & rule.options[1] & "'."
    checkType = "name"
    checkResult = true
    for child in exceptNode:
      try:
        if child.kind == nkIdent and ($child).toLowerAscii == rule.options[1].toLowerAscii:
          checkResult = false
          break
      except:
        discard

checkRule:
  initCheck:
    if rule.options[0] == "name" and rule.options.len < 2:
      rule.amount = errorMessage(text = "Can't check try statements' names. No name specified to check.")
      return
  startCheck:
    let negation: string = (if rule.negation: "'t" else: "")
  checking:
    if node.kind == nkTryStmt or (node.kind == nkStmtList and node[0].kind == nkTryStmt):
      let exceptNode: PNode = (if node.kind == nkTryStmt: node[^1] else: node[
          0][^1])
      var
        checkResult: bool = false
        message, checkType: string = ""
      # Check if the try statement contains general except statement
      if rule.options[0].toLowerAscii == "empty":
        checkEmpty(exceptNode = exceptNode, message = message,
            checkType = checkType, checkResult = checkResult, rule = rule)
      # Check if the try statement contains except with the selected exception
      if not checkResult and rule.options[0].toLowerAscii == "name":
        checkName(exceptNode = exceptNode, message = message,
            checkType = checkType, checkResult = checkResult, rule = rule)
      if rule.ruleType in {RuleTypes.count, search}:
        checkResult = not checkResult
      let oldAmount: int = rule.amount
      setResult(checkResult = checkResult, positiveMessage = positiveMessage,
          negativeMessage = negativeMessage, ruleData = checkType,
          node = exceptNode, params = [$exceptNode.info.line, message])
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
        if child.kind == nkTryStmt or (child.kind == nkStmtList and child[
            0].kind == nkTryStmt):
          let exceptNode: PNode = (if child.kind == nkTryStmt: child[
              ^1] else: child[0][^1])
          var
            checkResult: bool = false
            message, checkType: string = ""
          # Check if the try statement contains general except statement
          if rule.options[0].toLowerAscii == "empty":
            checkEmpty(exceptNode = exceptNode, message = message,
                checkType = checkType, checkResult = checkResult, rule = rule)
          # Check if the try statement contains except with the selected exception
          if not checkResult and rule.options[0].toLowerAscii == "name":
            checkName(exceptNode = exceptNode, message = message,
                checkType = checkType, checkResult = checkResult, rule = rule)
          if rule.ruleType in {RuleTypes.count, search}:
            checkResult = not checkResult
          let oldAmount: int = rule.amount
          setResult(checkResult = checkResult,
              positiveMessage = positiveMessage,
              negativeMessage = negativeMessage,
              ruleData = checkType,
              node = exceptNode, params = [$exceptNode.info.line, message])
          # To show the rule's explaination the rule.amount must be negative
          if rule.negation and oldAmount > rule.amount and rule.ruleType == check:
            rule.amount = -1_000
          if rule.ruleType == fix and not checkResult:
            return
  endCheck:
    discard

fixRule:
  discard
