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
##   [ruleType] ?not? comments
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. --Insert description
##   how rules types works with the rule--.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about --Insert description how negation affects the
##   rule--.
## * comments is the name of the rule. It is case-insensitive, thus it can be
##   set as *comments*, *comments* or *--rUlEnAmE--*.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "comments"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for procedure `proc main()`, the full declaration of it should
## be::
##
##     proc main () {.ruleOff: "comments".}
##
## To enable the rule again, the pragma *ruleOn: "comments"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `const a = 1`, the full declaration should
## be::
##
##     const a {.ruleOn: "comments".} = 1
##
## Examples
## --------
##
## --Insert rules examples--

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "comments",
  ruleFoundMessage = "comments which {negation}match the pattern found",
  ruleNotFoundMessage = "comments which {negation}match the pattern not found.",
  rulePositiveMessage = "comment, line: {params[0]} match the pattern '{params[1]}'.",
  ruleNegativeMessage = "comment, line: {params[0]} doesn't match the pattern '{params[1]}'.",
  ruleOptions = @[custom, str],
  ruleOptionValues = @["pattern"],
  ruleMinOptions = 2)

checkRule:
  initCheck:
    discard
  startCheck:
    let negation: string = (if rule.negation: "doesn't " else: "")
  checking:
    try:
      for line in lines(fileName = rule.fileName):
        let cleanLine: string = line.strip()
        if cleanLine.startsWith('#') and cleanLine.len > 2:
          echo cleanLine[2 .. ^1]
    except IOError:
      rule.amount = errorMessage(text = messagePrefix & "can't check file '" &
          rule.fileName & ". Reason: ", e = getCurrentException())
    break
  endCheck:
    discard

fixRule:
  discard
