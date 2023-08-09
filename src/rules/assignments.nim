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

## --Insert here the description of the rule--
## The syntax in a configuration file is::
##
##   [ruleType] ?not? assignments
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. --Insert description
##   how rules types works with the rule--.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about --Insert description how negation affects the
##   rule--.
## * assignments is the name of the rule. It is case-insensitive, thus it can be
##   set as *assignments*, *assignments* or *--rUlEnAmE--*.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "assignments"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for procedure `proc main()`, the full declaration of it should
## be::
##
##     proc main () {.ruleOff: "assignments".}
##
## To enable the rule again, the pragma *ruleOn: "assignments"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `const a = 1`, the full declaration should
## be::
##
##     const a {.ruleOn: "assignments".} = 1
##
## Examples
## --------
##
## --Insert rules examples--

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "assignments",
  ruleFoundMessage = "assignments which can{negation} be upgraded",
  ruleNotFoundMessage = "assignments which can{negation} be upgraded not found.",
  rulePositiveMessage = "assignments to '{params[0]}' line: {params[1]} can be updated to {params[2]}.",
  ruleNegativeMessage = "assignments to '{params[0]}' line: {params[1]} can't be updated to {params[2]}.",
  ruleOptions = @[custom],
  ruleOptionValues = @["shorthand"],
  ruleMinOptions = 1)

checkRule:
  initCheck:
    discard
  startCheck:
    discard
  checking:
    try:
      case rule.options[0].toLowerAscii
      of "shorthand":
        if node.kind == nkInfix:
          setResult(checkResult = true,
              positiveMessage = positiveMessage,
              negativeMessage = negativeMessage, node = node,
              ruleData = "shorthand", params = [$node[1], $node.info.line,
              (if rule.negation: "a full assignment" else: "a shorthand assignment")])
        elif node.kind == nkAsgn and $node[1][1] == $node[0]:
          setResult(checkResult = false,
              positiveMessage = negativeMessage,
              negativeMessage = positiveMessage, node = node,
              ruleData = "shorthand", params = [$node[0], $node.info.line,
              (if rule.negation: "a full assignment" else: "a shorthand assignment")])
      else:
        discard
    except Exception:
      rule.amount = errorMessage(text = messagePrefix & "can't check file '" &
          rule.fileName & ". Reason: ", e = getCurrentException())
      return
  endCheck:
    let negation: string = (if rule.negation and rule.ruleType in {check, fix}: "'t" else: "")

fixRule:
  discard
