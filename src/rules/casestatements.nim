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

## The rule to check do `case` statements in the code don't contain some
## expressions. Checked things:
##
## * The maximum and minimum amount of `case` statements' branches.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? caseStatements [checkType] [amount]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a `case` statement which violates any of the checks. Search
##   type will list all statements which violates any of checks or raise an
##   error if nothing found. Count type will simply list the amount of the
##   statements which violates the checks. Fix type will execute the default
##   shell command set by the program's setting **fixCommand**.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about the `case` statements which not violate the checks.
##   Probably useable only with search and count type of rule.
## * caseStatements is the name of the rule. It is case-insensitive, thus it can be
##   set as *casestatements*, *caseStatements* or *cAsEsTaTeMeNtS*.
## * checkType is the type of checks to perform on the `case` statements. Proper
##   values are: *min* and *max*. Setting it min will check if all `case`
##   statements have at least the selected amount of branches. Max value will
##   check if the `case` statements have maximum the selected amount of branches.
## * amount parameter is required for both types of checks. It is desired amount
##   of branches for the `case` statements, minimal or maximum, depends on
##   check's type.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "caseStatements"* in the code before it. For example,
## if the rule should be disabled for the statement, the full declaration of it
## should be::
##
##     {.ruleOff: "caseStatements".}
##     case a
##     of 1:
##       echo a
##
## To enable the rule again, the pragma *ruleOn: "caseStatements"* should be added
## in the code before it. For example, if the rule should be re-enabled for the
## statement, the full declaration should be::
##
##     {.ruleOn: "caseStatements".}
##     case a
##     of 1:
##       echo a
##
## Examples
## --------
##
## 1. Check if all `case` statements have at least 4 branches::
##
##     check caseStatements min 4

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "casestatements",
  ruleFoundMessage = "case statements which can{negation} be upgraded",
  ruleNotFoundMessage = "case statements which can{negation} be upgraded not found.",
  rulePositiveMessage = "case statement, line: {params[0]} {params[1]}",
  ruleNegativeMessage = "case statement, line: {params[0]} {params[1]}",
  ruleOptions = @[custom, integer],
  ruleOptionValues = @["min", "max"],
  ruleMinOptions = 2)

checkRule:
  initCheck:
    discard
  startCheck:
    discard
  checking:
    if node.kind == nkCaseStmt:
      var checkResult: bool = true
      if rule.options[0].toLowerAscii == "min":
        if node.len - 1 < rule.options[1].parseInt():
          checkResult = false
      elif node.len - 1 > rule.options[1].parseInt():
        checkResult = false
      if rule.ruleType == RuleTypes.count:
        checkResult = not checkResult
      setResult(checkResult = checkResult,
          positiveMessage = positiveMessage,
          negativeMessage = negativeMessage, node = node,
          ruleData = "amount", params = [$node.info.line,
          "the statement " & (if rule.negation: "doesn't have " else: "has ") &
          (if rule.options[0].toLowerAscii == "max": "more " else: "less ") &
              "than " & rule.options[1] & " branches."])
  endCheck:
    let negation: string = (if rule.negation: "'t" else: "")

fixRule:
  discard
