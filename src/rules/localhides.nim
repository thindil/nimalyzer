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

## The rule check if the local declarations in the module don't hide (have the
## same name) as a parent declarations declared in the module.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? localHides
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check rule will
##   raise an error if find a local declaration which has the same name as
##   one of parent declarations, search rule will list any local declarations
##   with the same name as previously declared parent and raise an error if
##   nothing found. Count rule will simply list the amount of local
##   declarations which have the same name as parent ones.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about local declarations which don't have name as
##   previously declared parent ones. Probably useable only for count type of
##   rule. Search type with negation will returns error as the last declaration
##   is always not hidden.
## * localHides is the name of the rule. It is case-insensitive, thus it can be
##   set as *localhides*, *localHides* or *lOcAlHiDeS*.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "localHides"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for procedure `proc main()`, the full declaration of it should
## be::
##
##     proc main () {.ruleOff: "localHides".}
##
## To enable the rule again, the pragma *ruleOn: "localHides"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `const a = 1`, the full declaration should
## be::
##
##     const a {.ruleOn: "localHides".} = 1
##
## Examples
## --------
##
## 1. Check if any local declaration hides the parent ones::
##
##     check localHides
##
## 2. Search for all local declarations which not hide the parent ones::
##
##     search not localHides

# External modules imports
import compiler/trees
# Import default rules' modules
import ../rules

ruleConfig(ruleName = "localhides",
  ruleFoundMessage = "local declarations which hide global declarations",
  ruleNotFoundMessage = "Local declarations which hide global declarations not found.")

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
    # The declaration is inside as injected a template or variable is ignored
    # or the declaration doesn't have initialization, ignore it and move to
    # the next declaration.
    if ' ' in varName or varName == "_" or node.len < 3:
      return

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

    proc checkChild(nodes: PNode): Natural {.raises: [], tags: [RootEffect],
        contractual.} =
      ## Check if the selected variable is hidden somewhere by a local variable
      ##
      ## * nodes - the list of nodes to check
      ##
      ## Returns the number of the line if the variable is hidden by a local variable,
      ## otherwise zero
      require:
        node != nil
      body:
        result = 0
        try:
          for childNode in nodes.items:
            if childNode.kind in {nkVarSection, nkLetSection, nkConstSection}:
              for declaration in childNode.items:
                if declaration[0].kind == nkIdent:
                  if varName == $declaration[0]:
                    return declaration.info.line
            result = checkChild(nodes = childNode)
            if result > 0:
              return
        except KeyError, Exception:
          discard

    # Check if the declaration can be updated
    var
      startChecking: bool = false
      hiddenLine: Natural = 0
    for child in nodesToCheck.items:
      if not startChecking and child == section:
        startChecking = true
        continue
      if startChecking:
        hiddenLine = checkChild(nodes = child)
        if hiddenLine > 0:
          break
    setResult(checkResult = hiddenLine == 0, rule = rule,
        positiveMessage = messagePrefix & "declaration of '" & $node[0] &
          "' line: " & $node.info.line & " is not hidden by local variable.",
        negativeMessage = messagePrefix & "declaration of '" & $node[0] &
          "' line: " & $node.info.line &
              " is hidden by local variable in line " &
          $hiddenLine & ".")

checkRule:
  initCheck:
    discard
  startCheck:
    discard
  checking:
    try:
      # Sometimes the compiler detects declarations as children of the node
      if node.kind in {nkVarSection, nkLetSection, nkConstSection}:
        # Check each variable declaration if meet the rule requirements
        for declaration in node.items:
          setCheckResult(node = declaration, section = node,
              parent = parentNode, messagePrefix = messagePrefix, rule = rule)
      # And sometimes the compiler detects declarations as the node
      elif node.kind == nkIdentDefs and astNode.kind in {nkVarSection,
          nkLetSection, nkConstSection}:
        setCheckResult(node = node, section = astNode, parent = parentNode,
            messagePrefix = messagePrefix, rule = rule)
    except KeyError, Exception:
      rule.amount = errorMessage(text = messagePrefix &
          "can't check declaration of variable " &
          " line: " &
          $node.info.line & ". Reason: ", e = getCurrentException())
  endCheck:
    discard
