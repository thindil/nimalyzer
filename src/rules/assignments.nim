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

## The rule to check do assignments in the code follow some design patterns.
## Checked things:
##
## * Do assignment is or not a shorthand assignment
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? assignments [checkType]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is an assignment which violates any of the checks. Search
##   type will list all assignments which violates any of checks or raise an
##   error if nothing found. Count type will simply list the amount of the
##   assignments which violates the checks. Fix type will try to upgrade the
##   assignment to meet the rule settings. For example, it will ugprade the
##   assignment to a shorthand assignment or replace by full if negation was
##   used.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about assignments which not violate the checks. For
##   example, it will raise an error when check type find a shorthand assignment.
## * assignments is the name of the rule. It is case-insensitive, thus it can be
##   set as *assignments*, *assignments* or *aSsIgNmEnTs*.
## * checkType is the type of checks to perform on the assignments. Proper
##   value is: *shorthand*. It will check if all assignments are shorthand
##   assignments.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "assignments"* in the element in code before it.
## For example, if the rule should be disabled for assignment `i = i + 1`, the
## full declaration of it should be::
##
##     {.ruleOff: "assignments".}
##     i = i + 1
##
## To enable the rule again, the pragma *ruleOn: "assignments"* should be added in
## the code before it. For example, if the rule should be re-enabled for `a += 1`,
## the full declaration should be::
##
##     {.ruleOn: "assignments".}
##     a += 1
##
## Examples
## --------
##
## 1. Check if all assignments in the code are shorthand assignments::
##
##     check assignments shorthand
##
## 2. Replace all shorthand assignments in the code with full assignments::
##
##     fix not assignments shorthand

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "assignments",
  ruleFoundMessage = "assignments which are{negation} shorthand assignment",
  ruleNotFoundMessage = "assignments which are{negation} shorthand assigments not found.",
  rulePositiveMessage = "assignments to '{params[0]}' line: {params[1]} {params[3]} {params[2]}.",
  ruleNegativeMessage = "assignments to '{params[0]}' line: {params[1]} {params[4]} {params[2]}.",
  ruleOptions = @[custom],
  ruleOptionValues = @["shorthand"],
  ruleMinOptions = 1)

checkRule:
  initCheck:
    rule.amount = 0
    if (rule.negation and rule.ruleType == RuleTypes.count) or rule.ruleType in
        {check, fix}:
      rule.amount.inc
  startCheck:
    discard
  checking:
    try:
      if node.kind == nkInfix:
        setResult(checkResult = true, positiveMessage = positiveMessage,
            negativeMessage = negativeMessage, node = node,
            ruleData = "shorthand", params = [$node[1], $node.info.line, (
            if rule.negation: "a full assignment" else: "a shorthand assignment"),
            (if rule.ruleType in {check,
            fix}: "can be updated to" else: "is"), (if rule.ruleType in {
            check, fix}: "can't be updated to" else: "isn't")])
      elif node.kind == nkAsgn:
        try:
          if node.sons[1].len < 3:
            continue
        except:
          continue
        if $node[1][1] == $node[0]:
          setResult(checkResult = false,
              positiveMessage = negativeMessage,
              negativeMessage = positiveMessage, node = node,
              ruleData = "shorthand", params = [$node[0], $node.info.line,
              (if rule.negation: "a full assignment" else: "a shorthand assignment"),
              (if rule.ruleType in {check,
              fix}: "can be updated to" else: "is"), (if rule.ruleType in {
              check, fix}: "can't be updated to" else: "isn't")])
    except Exception:
      rule.amount = errorMessage(text = messagePrefix & "can't check file '" &
          rule.fileName & ". Reason: ", e = getCurrentException())
      return
  endCheck:
    let negation: string = (if rule.negation: "'t" else: "")

fixRule:
  for index, child in parentNode:
    if child == astNode:
      let newInfix: PNode = newTree(kind = nkInfix, children = [])
      if rule.negation:
        let newAssignment: PNode = newTree(kind = nkAsgn, children = [])
        try:
          newAssignment.add(son = newIdentNode(ident = getIdent(
              ic = rule.identsCache, identifier = $astNode[1]),
              info = astNode.info))
          for i, part in astNode:
            if i > 0:
              newInfix.add(son = part)
            else:
              newInfix.add(son = newIdentNode(ident = getIdent(
              ic = rule.identsCache,
              identifier = $($part)[0 .. ^2]), info = astNode.info))
          newAssignment.add(son = newInfix)
          parentNode[index] = newAssignment
          return true
        except KeyError, Exception:
          discard errorMessage(text = "Can't upgrade an assignment. Reason: " &
              getCurrentExceptionMsg())
          return false
      else:
        try:
          for i, part in astNode[1]:
            if i > 0:
              newInfix.add(son = part)
            else:
              newInfix.add(son = newIdentNode(ident = getIdent(
              ic = rule.identsCache,
              identifier = $part & "="), info = astNode.info))
          parentNode[index] = newInfix
          return true
        except KeyError, Exception:
          discard errorMessage(text = "Can't upgrade an assignment. Reason: " &
              getCurrentExceptionMsg())
          return false
      return false
  return false
