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

## The rule checks if declarations of local variables can be changed from var
## to let or const and from let to const.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? varUplevel
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   error when the declaration of the variable can be changed into let or
##   const. Search type will list all declrations which can be updated and
##   count type will show the amount of variables' declarations which can be
##   updated.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about variables' declarations which can't be updated
##   to let or const.
## * varUplevel is the name of the rule. It is case-insensitive, thus it can be
##   set as *varuplevel*, *varUplevel* or *vArUpLeVeL*.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "varUplevel"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for variable `var i = 1`, the full declaration of it can be::
##
##     var i {.ruleOff: "varUplevel".} = 1
##
## To enable the rule again, the pragma *ruleOn: "varUplevel"* should be added in
## the element which should be checked or in the code before it. For example,
## if the rule should be re-enabled for `const a = 1`, the full declaration
## should be::
##
##     const a {.ruleOn: "varUplevel".} = 1
##
## Examples
## --------
##
## 1. Check if any declaration of local variable can be updated::
##
##     check varUplevel
##
## 2. Search for declarations of local variables which can't be updated::
##
##     search not varUplevel

# External modules imports
import compiler/trees
# Import default rules' modules
import ../rules

ruleConfig(ruleName = "varuplevel",
  ruleFoundMessage = "declarations which can{negation} be upgraded",
  ruleNotFoundMessage = "declarations which can{negation} be upgraded not found.")

proc setCheckResult(node, section, parent: PNode; messagePrefix: string;
    rule: var RuleOptions) {.raises: [KeyError, Exception], tags: [RootEffect],
    contractual.} =
  ## Set the check result for the rule
  ##
  ## * node          - the node which will be checked
  ## * section       - the section node of the node to check
  ## * parent        - the parent node of the declaration section
  ## * messagePrefix - the prefix added to the log message, set by the program
  ## * rule          - the rule options set by the user
  require:
    node != nil
    section != nil
    parent != nil
  body:
    let varName: string = $node[0]
    # The declaration is global, or inside as injected a template or variable
    # is ignored or the declaration doesn't have initialization, ignore it
    # and move to the next declaration.
    if varName.endsWith(suffix = '*') or ' ' in varName or varName ==
        "_" or node.len < 3:
      return
    var isUpdatable: bool = isDeepConstExpr(n = node[2])
    # Check if let declaration can be updated
    if section.kind == nkLetSection:
      setResult(checkResult = not isUpdatable, rule = rule,
          positiveMessage = "declaration of {params[0]} line: {params[1]} can't be updated to constant.",
          negativeMessage = "declaration of '{params[0]}' line: {params[1]} can be updated to constant.",
          messagePrefix = messagePrefix, params = [$node[0], $node.info.line])
    # Check if var declaration can be updated
    else:
      # No default value, can't be updated
      if node[2].kind == nkEmpty:
        isUpdatable = false
      # Has a default value, check if can be updated
      else:
        isUpdatable = true
        var nodesToCheck: PNode = nil
        # Find the AST nodes to check
        block findNodes:
          for nodes in parent.items:
            for baseNode in nodes.items:
              if baseNode == node:
                nodesToCheck = flattenStmts(n = parent)
                break findNodes
              for child in baseNode.items:
                if child == node:
                  nodesToCheck = flattenStmts(n = nodes)
                  break findNodes
                for subChild in child.items:
                  if subChild == node:
                    nodesToCheck = flattenStmts(n = baseNode)
                    break findNodes

        proc checkChild(nodes: PNode): bool {.raises: [], tags: [RootEffect],
            contractual.} =
          ## Check if the selected variable is assigned somewhere
          ##
          ## * nodes - the list of nodes to check
          ##
          ## Returns true if the variable is assigned somewhere after
          ## initialization, otherwise false
          require:
            nodes != nil
          body:
            result = false
            for child in nodes.items:
              try:
                if child.kind in {nkAsgn, nkDotExpr} and $child[0] == varName:
                  return true
                result = checkChild(nodes = child)
                if result:
                  break
              except KeyError, Exception:
                discard

        # Check if the declaration can be updated
        var startChecking: bool = false
        for child in nodesToCheck.items:
          if not startChecking and child == section:
            startChecking = true
            continue
          if startChecking:
            if checkChild(nodes = child):
              isUpdatable = false
              break
      setResult(checkResult = not isUpdatable, rule = rule,
          positiveMessage = "declaration of {params[0]} line: {params[1]} can't be updated to let.",
          negativeMessage = "declaration of '{params[0]}' line: {params[1]} can be updated to let.",
          messagePrefix = messagePrefix, params = [$node[0], $node.info.line])

checkRule:
  initCheck:
    discard
  startCheck:
    discard
  checking:
    try:
      # Sometimes the compiler detects declarations as children of the node
      if node.kind in {nkVarSection, nkLetSection}:
        # Check each variable declaration if meet the rule requirements
        for declaration in node.items:
          setCheckResult(node = declaration, section = node,
              parent = parentNode, messagePrefix = messagePrefix, rule = rule)
      # And sometimes the compiler detects declarations as the node
      elif node.kind == nkIdentDefs and astNode.kind in {nkVarSection,
          nkLetSection}:
        setCheckResult(node = node, section = astNode, parent = parentNode,
            messagePrefix = messagePrefix, rule = rule)
    except KeyError, Exception:
      rule.amount = errorMessage(text = messagePrefix &
          "can't check declaration of variable " & $node[0] &
          " line: " &
          $node.info.line & ". Reason: ", e = getCurrentException())
  endCheck:
    let negation: string = (if rule.negation: "'t" else: "")

fixRule:
  discard
