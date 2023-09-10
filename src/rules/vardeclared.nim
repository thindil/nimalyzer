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

## The rule to check if the selected variable declaration (var, let and const)
## has declared type and or value
## The syntax in a configuration file is::
##
##   [ruleType] ?not? varDeclared [declarationType]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a declaration isn't in desired pattern. Search type
##   will list all declarations with desired pattern and raise error if
##   nothing was found. Count type will simply list the amount of declarations
##   with the desired pattern. Fix type will execute the default shell command
##   set by the program's setting **fixCommand**.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about procedures without desired pattern.
##   Probably useable only with search and count type of rule.
## * varDeclared is the name of the rule. It is case-insensitive, thus it can be
##   set as *vardeclared*, *varDeclared* or *vArDeClArEd*.
## * declarationType is the desired type of variable's declaration to check.
##   Possible values are: full - the declaration must have declared type and
##   value for the variable, type - the declaration must have declared type for
##   the variable, value - the declaration must have declared value for the
##   variable.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "varDeclared"* before the block of code from which
## the rule should be disabled. For example, if the rule should be disabled for
## variable## `var a: int`, the full declaration of it should be::
##
##      {.ruleOff: "varDeclared".}
##      var a: int
##
## To enable the rule again, the pragma *ruleOn: "varDeclared"* should be added
## before the declaration which should be checked. For example, if the rule
## should be re-enabled for variable `let b = 2`, the full declaration should
## be::
##
##      {.ruleOn: "varDeclared".}
##      let b = 2
##
## Examples
## --------
##
## 1. Check if all declarations have set type and value for them::
##
##     check varDeclared full
##
## 2. Search for all declarations which don't set type for them::
##
##     search not varDeclared type

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "vardeclared",
  ruleFoundMessage = "declarations with{negation}{rule.options[0]} declaration",
  ruleNotFoundMessage = "declarations with{negation}{rule.options[0]} declaration not found.",
  rulePositiveMessage = "declaration of {params[0]} line: {params[1]} sets the {params[2]} '{params[3]}' as the {params[2]} of the variable.",
  ruleNegativeMessage = "declaration of '{params[0]}' line: {params[1]} doesn't set {params[2]} for the variable.",
  ruleOptions = @[custom],
  ruleOptionValues = @["full", "type", "value"],
  ruleMinOptions = 1)

checkRule:
  initCheck:
    discard
  startCheck:
    discard
  checking:
    try:
      # Sometimes the compiler detects declarations as children of the node
      if node.kind in {nkVarSection, nkLetSection, nkConstSection}:
        # Ignore declarations which are unpacked tuples
        if startsWith(s = $node[namePos], prefix = '('):
          continue
        # Check each variable declaration if meet the rule requirements
        for declaration in node.items:
          if declaration.len == 0:
            continue
          # Check if declaration of variable sets its type
          if rule.options[0] in ["full", "type"]:
            setResult(checkResult = declaration[^2].kind != nkEmpty,
                positiveMessage = positiveMessage,
                negativeMessage = negativeMessage, node = declaration,
                params = [$declaration[namePos], $declaration.info.line, "type",
                $declaration[1]])
          # Check if declaration of variable sets its value
          if rule.options[0] in ["full", "value"]:
            setResult(checkResult = declaration[^1].kind != nkEmpty,
                positiveMessage = positiveMessage,
                negativeMessage = negativeMessage, node = declaration,
                params = [$declaration[namePos], $declaration.info.line, "value",
                $declaration[2]])
      # And sometimes the compiler detects declarations as the node
      elif node.kind == nkIdentDefs and astNode.kind in {nkVarSection,
          nkLetSection, nkConstSection}:
        # Ignore declarations which are unpacked tuples
        if startsWith(s = $astNode[0], prefix = '('):
          continue
        # Check if declaration of variable sets its type
        if rule.options[0] in ["full", "type"]:
          setResult(checkResult = node[1].kind != nkEmpty,
              positiveMessage = positiveMessage,
              negativeMessage = negativeMessage, node = node, params = [$node[
              namePos], $node.info.line, "type", $node[1]])
        # Check if declaration of variable sets its value
        if rule.options[0] in ["full", "value"]:
          setResult(checkResult = node[2].kind != nkEmpty,
              positiveMessage = positiveMessage,
              negativeMessage = negativeMessage, node = node, params = [$node[
              namePos], $node.info.line, "value", $node[2]])
    except KeyError, Exception:
      rule.amount = errorMessage(text = messagePrefix &
          "can't check declaration of variable " &
          " line: " &
          $node.info.line & ". Reason: ", e = getCurrentException())
  endCheck:
    let negation: string = (if rule.negation: "out" else: "")

fixRule:
  discard
