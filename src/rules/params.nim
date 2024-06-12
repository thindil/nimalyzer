# Copyright © 2023-2024 Bartek Jasicki
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

## The rule to check the parameters of routines. Checked things:
##
## * Do the routine uses all its parameters.
## * Do the routine uses string or int for its parameters.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? params [checkType] [declarationType]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a procedure which doesn't use all its parameters.
##   Search type will list all procedures which uses their all parameters and
##   raise error if nothing was found. Count type will simply list the amount
##   of procedures which uses all their parameters. Fix type will remove the
##   unused parameter from the procedure's declaration. It will also stop
##   checking after remove. The fix type of the rule does nothing with negation.
##   Please read general information about the fix type of rules about potential
##   issues.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about procedures which have all parameters used.
##   Probably useable only with search and count type of rule.
## * params is the name of the rule. It is case-insensitive, thus it can be
##   set as *Params*, *params* or *pArAmS*.
## * checkType is the type of check to perform by the rule. Possible values:
##   `used`: check do all parameters of routines are used. `standardtypes`:
##   check do routines use string or int for their parameters. `all`: perform
##   all the rule's checks.
## * declarationType is the type of declaration which will be checked for the
##   parameters usage. Possible values: `procedures`: check all procedures,
##   functions and methods. `templates`: check templates only. `macros`: check
##   macros only. `all`: check all routines declarations (procedures,
##   functions, templates, macros, etc.).
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "params"* in the declaration from which the rule
## should be disabled or in code before it. For example, if the rule should be
## disabled for procedure `main()`, the full declaration of it should be::
##
##      proc main() {.ruleOff: "params".}
##
## To enable the rule again, the pragma *ruleOn: "params"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for function `myFunc(a: int)`, the full
## declaration should be::
##
##      func myFunc(a: int) {.ruleOn: "params".}
##
## Examples
## --------
##
## 1. Check if all procedures in module uses their parameters::
##
##     check params used procedures
##
## 2. Search for all declarations which don't use their all parameters::
##
##     search not params used all

# External modules imports
import compiler/trees
# Import default rules' modules
import ../rules

ruleConfig(ruleName = "params",
  ruleFoundMessage = "procedures which{negation} {ruleCheck}",
  ruleNotFoundMessage = "procedures which{negation} {ruleCheck} not found.",
  rulePositiveMessage = "procedure {params[0]} line: {params[1]}{params[2]} use all its parameters.",
  ruleNegativeMessage = "procedure {params[0]} line: {params[1]} doesn't use parameter '{params[2]}'.",
  ruleOptions = @[str, custom],
  ruleOptionValues = @["procedures", "templates", "macros", "all"],
  ruleMinOptions = 2)

checkRule:
  initCheck:
    if rule.options[0].toLowerAscii notin ["all", "used", "standardtypes"]:
      rule.amount = errorMessage(text = "Can't check the parameters of routines, invalid check type set in the configuration file.")
      return
  startCheck:
    let nodesToCheck: set[TNodeKind] = case rule.options[1]
      of "all":
        routineDefs
      of "procedures":
        {nkProcDef, nkFuncDef, nkMethodDef}
      of "templates":
        {nkTemplateDef}
      of "macros":
        {nkMacroDef}
      else:
        {}
  checking:
    if node.kind in nodesToCheck:
      type NodeName = string
      # Get the procedure's name
      let procName: NodeName = try:
            $node[0]
          except KeyError, Exception:
            ""
      if procName.len == 0:
        rule.amount = errorMessage(
            text = "Can't get the name of the procedure.")
        return
      # No parameters, skip
      if node[paramsPos].len < 2:
        if rule.negation:
          rule.amount.dec
        else:
          rule.amount.inc
      # No body, definition only, skip
      if rule.options[0].toLowerAscii == "used" and node[bodyPos].len == 0:
        continue
      var index: ExtendedNatural = -1
      # Check each parameter
      for child in node[paramsPos].sons[1..^1]:
        index = -1
        for i in 0..child.len - 3:
          try:
            let varName: NodeName = split(s = $child[i])[0]
            # Check if the routine uses all its parameters
            if rule.options[0].toLowerAscii in ["all", "used"]:
              let body: PNode = flattenStmts(n = node[bodyPos])
              for childNode in body:
                index = find(s = $childNode, sub = varName)
                if index > -1:
                  break
              # The node doesn't use one of its parameters
              if index == -1:
                if rule.negation:
                  setResult(checkResult = false, positiveMessage = "",
                      negativeMessage = positiveMessage, node = node, params = [
                      procName, $node.info.line, " doesn't"])
                  break
                setResult(checkResult = false, positiveMessage = "",
                    negativeMessage = negativeMessage, ruleData = varName,
                    node = node, params = [procName, $node.info.line, varName])
                if rule.ruleType == fix:
                  return
            # Check if the routine uses standard types for its parameters
            if rule.options[0].toLowerAscii in ["all", "standardtypes"]:
              var checkResult: bool = if rule.ruleType == check:
                  $child[^2] in ["int", "string"]
                else:
                  $child[^2] notin ["int", "string"]
              if rule.ruleType != check:
                checkResult = not checkResult
              setResult(checkResult = checkResult,
                  positiveMessage = "procedure {params[0]} line: {params[1]} parameter '{params[2]}' use " &
                  $child[^2] & " as type.",
                  negativeMessage = "procedure {params[0]} line: {params[1]} parameter '{params[2]}' doesn't use int or string as type.",
                  ruleData = varName, node = node, params = [procName,
                  $node.info.line, varName])
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
    let
      negation: Message = (if rule.negation: " not" else: "")
      ruleCheck: Message = case rule.options[0].toLowerAscii
        of "all":
          "pass all checks"
        of "used":
          "use all parameters"
        of "standardtypes":
          "contain int or string as type of parameters"
        else:
          ""

fixRule:
  # Don't change anything if rule has negation or the rule is set to check more
  # than only used parameters
  if rule.negation or rule.options[0].toLowerAscii != "used":
    return false
  # Remove unused parameters
  block removeUnusedParam:
    for index, child in astNode[paramsPos]:
      if child.kind == nkIdentDefs:
        for iindex, ident in child:
          try:
            if $ident == data:
              astNode[paramsPos][index].delSon(idx = iindex)
              break removeUnusedParam
          except KeyError, Exception:
            discard errorMessage(text = "Can't remove unused parameter. Reason: " &
                getCurrentExceptionMsg())
            return false
  return true
