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

## The rule to check if all calls in the code uses named parameters
## The syntax in a configuration file is::
##
##   [ruleType] ?not? namedParams
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a call which doesn't have all parameters named.
##   Search type will list all calls which set all their parameters as named
##   and raise error if nothing was found. Count type will simply list the
##   amount of calls which set all their parameters as named.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about calls which have some parameters not named.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "namedParams"* before the code's fragment which
## shouldn't be checked.
##
## To enable the rule again, the pragma *ruleOn: "namedParams"* should be added
## before the code which should be checked.
##
## Examples
## --------
##
## 1. Check if all calls in module set their parameters as named::
##
##     check namedParams
##
## 2. Search for all calls which don't set their parameters as named::
##
##     search not namedParams

# Import default rules' modules
import ../rules

const
  ruleName*: string = "namedparams" ## The name of the rule used in a configuration file
  ruleOptions*: seq[RuleOptionsTypes] = @[] ## The list of options required by the rule
  ruleOptionValues*: seq[string] = @[] ## The list of custom option values for the rule
  ruleMinOptions*: Natural = ruleOptions.len ## The minimum amount of options required by the rule

proc ruleCheck*(astTree: PNode; options: var RuleOptions) {.contractual,
    raises: [], tags: [RootEffect].} =
  ## Check recursively if calls in the source code use named paramters.
  ##
  ## * astTree - The AST tree representation of the Nim code to check
  ## * options - The rule options set by the user and the previous iterations
  ##             of the procedure
  ##
  ## The amount of result how many calls in the source code use named parameters.
  require:
    astTree != nil
    options.fileName.len > 0
  body:

    proc check(node: PNode; options: var RuleOptions) {.contractual, raises: [], tags: [RootEffect].} =
      ## Check the call if it uses named parameters
      ##
      ## * node      - the AST node representing the call to check
      ## * options   - the rule options set by the user and the previous iterations
      ##               of the procedure
      ##
      ## Returns the updated parameter options.
      require:
        node != nil
      body:
        if not options.enabled:
          return
        let messagePrefix: string = if getLogFilter() < lvlNotice:
            ""
          else:
            options.fileName & ": "
        let callName: string = try:
              $node[0]
            except KeyError, Exception:
              ""
        if callName.len == 0:
          message(text = "Can't get the name of the call.", level = lvlFatal,
              returnValue = options.amount)
          options.amount.inc
          return
        try:
          for i in 1..<node.sons.len:
            setResult(checkResult = node[i].kind == nkExprEqExpr,
                options = options, positiveMessage = messagePrefix & "call " &
                callName & " line: " & $node.info.line &
                " doesn't have named parameter number: " & $i & "'.",
                negativeMessage = messagePrefix & "call " & callName &
                " line: " & $node.info.line &
                " doesn't have named parameter number: " & $i & "'.")
        except KeyError, Exception:
          options.amount = errorMessage(text = messagePrefix &
              "can't check parameters of call " & callName & " line: " &
              $node.info.line & ". Reason: ", e = getCurrentException())

    let isParent: bool = options.parent
    if isParent:
      options.parent = false
    setRuleState(node = astTree, ruleName = ruleName,
        oldState = options.enabled)
    if astTree.kind == nkCall:
      check(node = astTree, options = options)
      return
    for node in astTree.items:
      setRuleState(node = node, ruleName = ruleName, oldState = options.enabled)
      # Node is a call, and have parameters, check it
      if node.kind == nkCall and (node.sons.len > 1 and node.sons[1].kind != nkStmtList):
        check(node = node, options = options)
      # Check the node's children with the rule
      for child in node.items:
        ruleCheck(astTree = child, options = options)
    if isParent:
      showSummary(options = options, foundMessage = "calls which" & (
          if options.negation: " not" else: "") & " have all named parameters",
          notFoundMessage = "calls which" & (
          if options.negation: " not" else: "") & " have all named parameters not found.")

proc validateOptions*(options: seq[string]): bool {.contractual, raises: [],
    tags: [RootEffect].} =
  ## Validate the options entered from a configuration for the rule
  ##
  ## * options - the list of options entered from a configuration file
  ##
  ## Returns true if options are valid otherwise false.
  body:
    if options.len > 0:
      return errorMessage(text = "The rule namedParams doesn't accept any options, but options suplied: '" &
          options.join(", ") & "'.").bool
    return true
