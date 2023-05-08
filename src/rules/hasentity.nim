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

## The rule to check if the selected module has the selected entities, like
## procedures, constants, etc. with the selected names. The syntax in a
## configuration file is::
##
##   [ruleType] ?not? hasentity [entityType] [entityName] ?parentEntity? ?childIndex?
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if the selected type of entity with the selected name was not
##   found in the module. Search type will list all entities of the selected
##   type with the selected name and raise error if nothing was found. Count
##   type will simply list the amount of the selected entities.
## * optional word *not* means negation for the rule. For example, if rule is
##   set to check for procedures named myProc, adding word *not* will change
##   to inform only about modules without the procedure with that name.
## * hasentity is the name of the rule. It is case-insensitive, thus it can be
##   set as *hasentity*, *hasEntity* or *hAsEnTiTy*.
## * entityType is the type of entity which will be looking for. Proper values
##   are types used by Nim compiler, defined in file compiler/ast.nim in
##   enumeration *TNodeKind*. Examples: *nkType*, *nkCall*.
## * entityName is the name of entity which will be looking for. The rule
##   search for the selected entity type, which name starts with entityName.
##   For example, if entityType is set to nkProcDef and entityName is set to
##   *myProc* the rule will find procedures named *myProc*, but also *myProcedure*.
## * if optional parameter *parentEntity* is set then the entity will be searched
##   only as a child of the selected type of entities. For example setting
##   entityType to nkProcDef, entityName to myProc and parentEntity to nkStmtList
##   will find all nested procedures with name *myProc* or *myProcedure*.
## * if optional parameter *childIndex* is set, then the entity will be searched
##   only as the selected child of the selected parent. In order for
##   `*childIndex` parameter to work, the parameter *parentEntity* must be set
##   too. If the value of the *childIndex* is a natural number, it is the index of
##   the child counted from the beginning of the list of children. If the value is
##   negative, it is the index of the child counted from the end of the list of
##   children.
##
## To look only for global entities, add `*` to the end of the entityName
## parameter. Setting it to *MyProc\** will look only for global entities
## which full name is MyProc.
##
## Note
## ----
##
## hasEntity rule is considered as a low level rule. It requires a
## knowledge about Nim compiler, especially names of the Nim code nodes and the
## generated source code tree to use. It is recommended to use other rules
## instead of this one.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "hasEntity"* before the code's fragment which
## shouldn't be checked.
##
## To enable the rule again, the pragma *ruleOn: "hasEntity"* should be added
## before the code which should be checked.
##
## Examples
## --------
##
## 1. Check if module has declared global procedure with name *myProc*::
##
##     check hasEntity nkProcDef myProc*
##
## 2. Search for all defined global constants::
##
##     search hasEntity nkConstSection *
##
## 3. Count the amount of global enumerations::
##
##     count hasEntiry nkEnumTy *
##
## 4. Check if there are no declarations of global range types::
##
##     check not hasEntity nkRange *

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "hasentity",
  ruleFoundMessage = "declared {rule.options[0]} with name '{rule.options[1]}'",
  ruleNotFoundMessage = "doesn't have declared {rule.options[0]} with name '{rule.options[1]}'.",
  ruleOptions = @[node, str, node, integer],
  ruleMinOptions = 2,
  ruleShowForCheck = true)

proc checkEntity(nodeName, line: string; rule: var RuleOptions; hasPrefix: bool) {.raises: [],
    tags: [RootEffect], contractual.} =
  ## Check if the selected entity's name fulfill the rule requirements and
  ## log the message if needed.
  ##
  ## * nodeName - the name of the entity which will be checked
  ## * line     - the line of code in which the entity is declared
  ## * rule     - the rule options set by the user and the previous iterations
  ##              of the procedure
  ##
  ## Returns the updated rule parameter
  if not rule.enabled:
    return
  # The selected entity found in the node
  if rule.options[1].len == 0 or startsWith(s = nodeName, prefix = rule.options[1]):
    setResult(checkResult = true, rule = rule, positiveMessage = (
        if not hasPrefix: "H" else: rule.fileName & ": h") &
        "as declared " & rule.options[0] & " with name '" & nodeName &
        "' at line: " & line & ".", negativeMessage = (if not hasPrefix:
        "H" else: rule.fileName & ": h") & "as declared " &
        rule.options[0] & " with name '" & nodeName & "' at line: " & line & ".")

checkRule:
  initCheck:
    rule.amount = 0
    if rule.negation:
      rule.amount.inc
  startCheck:
    # Set the type of the node to check
    let nodeKind: TNodeKind = try:
          parseEnum[TNodeKind](s = rule.options[0])
        except ValueError:
          nkNone
    if nodeKind == nkNone:
      rule.amount = errorMessage(text = "Invalid type of entity: " &
          rule.options[0])
      return
  checking:
    if node.kind notin {nkEmpty .. nkSym, nkCharLit .. nkTripleStrLit,
        nkCommentStmt}:
      try:
        # If parent node specified and the current node is the same kind as
        # the parent node, check its children instead of the node
        if rule.options.len > 2:
          let parentKind: TNodeKind = try:
                parseEnum[TNodeKind](s = rule.options[2])
              except ValueError:
                nkNone
          var childIndex: int = -1
          if rule.options.len == 4:
            childIndex = try:
                rule.options[3].parseInt()
              except ValueError:
                int.low
          if node.kind == parentKind:
            if childIndex == int.low:
              for child in node.items:
                if child.kind != nodeKind:
                  continue
                let childName: string = try:
                    $child[0]
                  except KeyError, Exception:
                    ""
                checkEntity(nodeName = childName, line = $child.info.line,
                    rule = rule, hasPrefix = messagePrefix.len > 0)
            elif childIndex <= node.sons.high:
              let childName: string = try:
                  if childIndex > -1:
                    $node[childIndex]
                  else:
                    $node[^childIndex]
                except KeyError, Exception:
                  ""
              checkEntity(nodeName = childName, line = $node.info.line,
                  rule = rule, hasPrefix = messagePrefix.len > 0)
        # Check the node itself
        elif node.kind == nodeKind:
          checkEntity(nodeName = $node[0], line = $node.info.line,
              rule = rule, hasPrefix = messagePrefix.len > 0)
      except KeyError, Exception:
        rule.amount = errorMessage(
            text = "Error during checking hasEntity rule: ",
            e = getCurrentException())
        return
  endCheck:
    discard

fixRule:
  discard
