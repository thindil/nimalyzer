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

## Count the complexity of the selected code. Possible complexity formulas:
## cyclomatic.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? complexity [checkType] [codeType] [value]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if the selected type of code block has complexity above the selected
##   value. Search type will list all code blocks of the selected
##   type with the complexity above the selected value and raise error if nothing
##   was found. Count type will simply list the amount of the selected code
##   blocks with complexity above the value. Fix type will execute the default
##   shell command set by the program's setting **fixCommand**.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about code blocks with complexity below the selected
##   value.
## * complexity is the name of the rule. It is case-insensitive, thus it can be
##   set as *complexity*, *complexity* or *--cOmPlExItY--*.
## * checkType is the type of complexity to check. Proper value is *cyclomatic*.
##   Setting it to cyclomatic value will set the rule to count cyclomatic
##   complexity of the selected code blocks.
## * codeType -  the type of code blocks to check by the rule. Proper values
##   are: *all*, *routines*, *loops*, *conditions*. Setting it to all will count
##   the complexity of all code blocks in the code. Routines value will check
##   only routines (like procedures, functions, iterators, etc.) declarations.
##   Loops value will check only loops (for and while). Conditions value will
##   check only conditional statements (if and when).
## * Value is the maximum or minimum for negation type of the rule, value of
##   complexity allowed for the selected code blocks. For cyclomatic complexity
##   the value should be: 1-10 for low risk code, 11-20 for medium risk code,
##   21-50 for high risk code and 50+ for very high risk code.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "complexity"* in the code before it. For example,
## if the rule should be disabled for the procedure main declaration, the full
## declaration of it should be::
##
##     {.ruleOff: "complexity".}
##     proc main() =
##       discard
##
## To enable the rule again, the pragma *ruleOn: "complexity"* should be added in
## the code before it. For example, if the rule should be re-enabled for if statement,
## the full declaration should be::
##
##     {.ruleOn: "complexity".}
##     if a == 1:
##       echo a
##
## Examples
## --------
##
## 1. Check if all code blocks are maximum high risk code in cyclomatic complexity::
##
##     check complexity cyclomatic all 50
##
## 2. Search for procedures declaration which cyclomatic complexity is below medium risk::
##
##     search not complexity cyclomatic routines 20

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "complexity",
  ruleFoundMessage = "Code blocks with the complexity {moreOrLess} the selected found",
  ruleNotFoundMessage = "Code blocks with the complexity {moreOrLess} the selected not found.",
  rulePositiveMessage = "Code block at line: {params[0]} has {params[1]} complexity less or equal to {params[2]} ({params[3]}).",
  ruleNegativeMessage = "Code block at line: {params[0]} has {params[1]} complexity more than {params[2]} ({params[3]}).",
  ruleOptions = @[custom, str, integer],
  ruleOptionValues = @["cyclomatic"],
  ruleMinOptions = 3)

proc countCyclomatic(complexity: var Positive; node: PNode) {.raises: [KeyError,
    Exception], tags: [RootEffect], contractual.} =
  ## Count the cyclomatic complexity of the selected code's branch
  ##
  ## * complexity - the current complexity of the checked code
  ## * node       - the code's branch which will be checked for complexity
  ##
  ## Returns updated parameter complexity
  require:
    node != nil
  body:
    for child in node:
      if child.kind in {nkCharLit .. nkSym}:
        continue
      if child.kind in {nkForStmt, nkWhileStmt, nkElifBranch, nkWhenStmt,
          nkIfExpr} or (child.kind == nkIdent and $child in ["and", "or"]):
        complexity.inc
      countCyclomatic(complexity = complexity, node = child)

checkRule:
  initCheck:
    discard
  startCheck:
    let nodesToCheck: set[TNodeKind] = case rule.options[1].toLowerAscii
      of "all":
        callableDefs + {nkForStmt, nkWhileStmt, nkIfStmt, nkElifBranch, nkWhenStmt}
      of "routines":
        routineDefs
      of "loops":
        {nkForStmt, nkWhileStmt}
      of "conditions":
        {nkIfStmt, nkElifBranch, nkWhenStmt}
      else:
        {}
    if nodesToCheck == {}:
      rule.amount = errorMessage(text = "Can't check the complexity of the code, unknown type of a code to check: '" &
          rule.options[1] & "'. Should be one of: 'all', 'routines', 'loops', 'conditions'")
      return
  checking:
    if node.kind in nodesToCheck:
      var complexity: Positive = 2
      try:
        for child in node:
          countCyclomatic(complexity = complexity, node = child)
        setResult(checkResult = complexity <= rule.options[2].parseInt,
            positiveMessage = positiveMessage,
                negativeMessage = negativeMessage,
            node = node, params = [$node.info.line, rule.options[0],
                rule.options[
            2], $complexity])
      except Exception:
        rule.amount = errorMessage(text = messagePrefix &
            "can't check code block at " & $node.info.line & " line. Reason: ",
            e = getCurrentException())
        return
  endCheck:
    let moreOrLess: string = (if rule.negation: "more than" else: "less or equal to")

fixRule:
  discard
