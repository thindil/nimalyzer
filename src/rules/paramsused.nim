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

## The rule to check if the selected procedure uses all its parameter
## The syntax in a configuration file is::
##
##   [ruleType] ?not? paramsUsed [declarationType]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a procedure which doesn't use all its parameters.
##   Search type will list all procedures which uses their all parameters and
##   raise error if nothing was found. Count type will simply list the amount
##   of procedures which uses all their parameters. Fix type will execute the
##   default shell command set by the program's setting **fixCommand**.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about procedures which have all parameters used.
##   Probably useable only with search and count type of rule.
## * paramsUsed is the name of the rule. It is case-insensitive, thus it can be
##   set as *paramsUsed*, *paramsUsed* or *pArAmSuSeD*.
## * declarationType is the type of declaration which will be checked for the
##   parameters usage. Possible values: `procedures`: check all procedures,
##   functions and methods. `templates`: check templates only. `all`: check
##   all routines declarations (procedures, functions, templates, macros, etc.).
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "paramsUsed"* in the declaration from which the rule
## should be disabled or in code before it. For example, if the rule should be
## disabled for procedure `main()`, the full declaration of it should be::
##
##      proc main() {.ruleOff: "paramsUsed".}
##
## To enable the rule again, the pragma *ruleOn: "paramsUsed"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for function `myFunc(a: int)`, the full
## declaration should be::
##
##      func myFunc(a: int) {.ruleOn: "paramsUsed".}
##
## Examples
## --------
##
## 1. Check if all procedures in module uses their parameters::
##
##     check paramsUsed procedures
##
## 2. Search for all declarations which don't use their all parameters::
##
##     search not paramsUsed all

# External modules imports
import compiler/trees
# Import default rules' modules
import ../rules

ruleConfig(ruleName = "paramsused",
  ruleFoundMessage = "procedures which{negation} uses all parameters",
  ruleNotFoundMessage = "procedures which{negation} uses all parameters not found.",
  rulePositiveMessage = "procedure {params[0]} line: {params[1]}{params[2]} use all parameters.",
  ruleNegativeMessage = "procedure {params[0]} line: {params[1]} doesn't use parameter '{params[2]}'.",
  ruleOptions = @[custom],
  ruleOptionValues = @["procedures", "templates", "all"],
  ruleMinOptions = 1)

checkRule:
  initCheck:
    discard
  startCheck:
    let nodesToCheck: set[TNodeKind] = case rule.options[0]
      of "all":
        routineDefs
      of "procedures":
        {nkProcDef, nkFuncDef, nkMethodDef}
      of "templates":
        {nkTemplateDef}
      else:
        {}
  checking:
    if node.kind in nodesToCheck:
      # Get the procedure's name
      let procName: string = try:
            $node[0]
          except KeyError, Exception:
            ""
      if procName.len == 0:
        rule.amount = errorMessage(
            text = "Can't get the name of the procedure.")
        return
      # No parameters, skip
      if node[3].len < 2:
        if rule.negation:
          rule.amount.dec
        else:
          rule.amount.inc
      else:
        var index: int = -1
        # Check each parameter
        for child in node[3]:
          if child.kind in {nkEmpty, nkIdent}:
            continue
          index = -1
          for i in 0..child.len - 3:
            try:
              let
                varName: string = split(s = $child[i])[0]
                body: PNode = flattenStmts(n = node[6])
              for childNode in body.items:
                index = find(s = $childNode, sub = varName)
                if index > -1:
                  break
              # The node doesn't use one of its parameters
              if index == -1:
                if not rule.negation:
                  setResult(checkResult = false, positiveMessage = "",
                      negativeMessage = negativeMessage, node = node, params = [
                      procName, $node.info.line, varName])
                else:
                  setResult(checkResult = false, positiveMessage = "",
                      negativeMessage = positiveMessage, node = node, params = [
                      procName, $node.info.line, " doesn't"])
                  break
            except KeyError, Exception:
              rule.amount = errorMessage(text = messagePrefix &
                  "can't check parameters of procedure " & procName &
                  " line: " &
                  $node.info.line & ". Reason: ", e = getCurrentException())
        # The node uses all of its parameters
        if index > -1:
          setResult(checkResult = true, positiveMessage = positiveMessage,
              negativeMessage = positiveMessage, node = node, params = [
              procName, $node.info.line, ""])
  endCheck:
    let negation: string = (if rule.negation: " not" else: "")

fixRule:
  discard
