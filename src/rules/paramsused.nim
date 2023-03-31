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
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a procedure which doesn't use all its parameters.
##   Search type will list all procedures which uses their all parameters and
##   raise error if nothing was found. Count type will simply list the amount
##   of procedures which uses all their parameters.
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
## should be disabled. For example, if the rule should be disabled for procedure
## `main()`, the full declaration of it should be::
##
##      proc main() {.ruleOff: "paramsUsed".}
##
## To enable the rule again, the pragma *ruleOn: "paramsUsed"* should be added in
## the element which should be checked. For example, if the rule should be
## re-enabled for function `myFunc(a: int)`, the full declaration should be::
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

# Import default rules' modules
import ../rules

const
  ruleName*: string = "paramsused" ## The name of the rule used in a configuration file
  ruleOptions*: array[1, RuleOptionsTypes] = [
    custom] ## The list of options required by the rule
  ruleOptionValues*: array[3, string] = ["procedures", "templates",
      "all"] ## The list of custom option values for the rule

proc ruleCheck*(astTree: PNode; options: var RuleOptions) {.contractual,
    raises: [], tags: [RootEffect].} =
  ## Check recursively if all procedures in the Nim code use all of their
  ## parameters
  ##
  ## * astTree - The AST tree representation of the Nim code to check
  ## * options - The rule options set by the user and the previous iterations
  ##             of the procedure
  ##
  ## The amount of result how many procedures uses their all parameters
  require:
    astTree != nil
    options.fileName.len > 0
  body:
    let isParent: bool = options.parent
    if isParent:
      options.parent = false
    let
      messagePrefix: string = if getLogFilter() < lvlNotice:
          ""
        else:
          options.fileName & ": "
      nodesToCheck: set[TNodeKind] = case options.options[0]
        of "all":
          routineDefs
        of "procedures":
          {nkProcDef, nkFuncDef, nkMethodDef}
        of "templates":
          {nkTemplateDef}
        else:
          {}
    for node in astTree.items:
      # Check the node's children if rule is enabled
      for child in node.items:
        setRuleState(node = child, ruleName = ruleName,
            oldState = options.enabled)
      if options.enabled and node.kind in nodesToCheck:
        # Get the procedure's name
        let procName: string = try:
              $node[0]
            except KeyError, Exception:
              ""
        if procName.len == 0:
          options.amount = errorMessage(
              text = "Can't get the name of the procedure.")
          return
        # No parameters, skip
        if node[3].len < 2:
          if options.negation:
            options.amount.dec
          else:
            options.amount.inc
        else:
          var index: int = -1
          # Check each parameter
          for child in node[3]:
            if child.kind in {nkEmpty, nkIdent}:
              continue
            index = -1
            for i in 0..child.len - 3:
              try:
                index = find(s = $node[6], sub = $child[i])
                # The node doesn't use one of its parameters
                if index == -1:
                  if not options.negation:
                    setResult(checkResult = false, options = options,
                        positiveMessage = "", negativeMessage = messagePrefix &
                        "procedure " & procName & " line: " & $node.info.line &
                        " doesn't use parameter '" & $child[i] & "'.")
                  else:
                    setResult(checkResult = false, options = options,
                        positiveMessage = "", negativeMessage = messagePrefix &
                        "procedure " & procName & " line: " & $node.info.line & " doesn't use all parameters.")
                    break
              except KeyError, Exception:
                options.amount = errorMessage(text = messagePrefix &
                    "can't check parameters of procedure " & procName &
                    " line: " &
                    $node.info.line & ". Reason: ", e = getCurrentException())
          # The node uses all of its parameters
          if index > -1:
            setResult(checkResult = true, options = options,
                positiveMessage = "", negativeMessage = messagePrefix &
                "procedure " & procName & " line: " & $node.info.line & " use all parameters.")
      # Check the node's children with the rule
      for child in node.items:
        ruleCheck(astTree = child, options = options)
    if isParent:
      showSummary(options = options, foundMessage = "procedures which" & (
          if options.negation: " not" else: "") & " uses all parameters",
          notFoundMessage = "procedures which" & (
          if options.negation: " not" else: "") & " uses all parameters not found.")

proc validateOptions*(options: seq[string]): bool {.contractual, raises: [],
    tags: [RootEffect].} =
  ## Validate the options entered from a configuration for the rule
  ##
  ## * options - the list of options entered from a configuration file
  ##
  ## Returns true if options are valid otherwise false.
  body:
    if options.len < 1:
      return errorMessage(text = "The rule paramsUsed require type of entities to check, but nothing was supplied.").bool
    if options[0] notin ["procedures", "templates", "all"]:
      return errorMessage(text = "The option for the rule paramsUsed must be type of enties to check, but got: '" &
          options[0] & "'.").bool
    return true
