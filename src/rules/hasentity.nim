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

const ruleName*: string = "hasentity" ## The name of the rule used in a configuration file

proc ruleCheck*(astTree: PNode; options: var RuleOptions) {.contractual,
    raises: [], tags: [RootEffect].} =
  ## Check recursively if the source code has the selected entity
  ##
  ## * astTree - The AST tree representation of the Nim code to check
  ## * options - The rule options set by the user and the previous iterations
  ##             of the procedure
  ##
  ## The amount of result how many times the selected elements of the Nim code
  ## were found
  require:
    astTree != nil
    options.options.len > 1
    options.fileName.len > 0
  body:
    # Set the type of the node to check
    let nodeKind: TNodeKind = try:
          parseEnum[TNodeKind](s = options.options[0])
        except ValueError:
          nkNone
    if nodeKind == nkNone:
      options.amount = errorMessage(text = "Invalid type of entity: " &
          options.options[0])
      return
    let isParent: bool = options.parent
    if isParent:
      options.parent = false
    if options.negation and isParent:
      options.amount.inc

    proc checkEntity(nodeName, line: string; options: RuleOptions;
        oldResult: var int) {.raises: [], tags: [RootEffect], contractual.} =
      ## Check if the selected entity's name fulfill the rule requirements and
      ## log the message if needed.
      ##
      ## * nodeName  - the name of the entity which will be checked
      ## * line      - the line of code in which the entity is declared
      ## * oldResult - the previous amount of the rule result value
      ##
      ## Returns the updated oldResult parameter
      if not options.enabled:
        return
      # The selected entity found in the node
      if options.options[1].len == 0 or startsWith(s = nodeName,
          prefix = options.options[1]):
        if options.negation:
          if options.ruleType == check:
            message(text = (if getLogFilter() <
                lvlNotice: "H" else: options.fileName & ": h") &
                "as declared " & options.options[0] & " with name '" &
                nodeName & "' at line: " & line & ".",
                returnValue = oldResult)
            oldResult = int.low
          else:
            oldResult.dec
        else:
          if options.ruleType != search:
            oldResult.inc
          else:
            message(text = (if getLogFilter() <
                lvlNotice: "H" else: options.fileName & ": h") &
                "as declared " & options.options[0] & " with name '" &
                nodeName & "' at line: " & line & ".",
                returnValue = oldResult, level = lvlNotice, decrease = false)

    for node in astTree.items:
      setRuleState(node = node, ruleName = ruleName, oldState = options.enabled)
      if node.kind notin {nkEmpty .. nkSym, nkCharLit .. nkTripleStrLit,
          nkCommentStmt}:
        try:
          # If parent node specified and the current node is the same kind as
          # the parent node, check its children instead of the node
          if options.options.len > 2:
            let parentKind: TNodeKind = try:
                  parseEnum[TNodeKind](s = options.options[2])
                except ValueError:
                  nkNone
            var childIndex: int = -1
            if options.options.len == 4:
              childIndex = try:
                  options.options[3].parseInt()
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
                      options = options, oldResult = options.amount)
              elif childIndex <= node.sons.high:
                let childName: string = try:
                    if childIndex > -1:
                      $node[childIndex]
                    else:
                      $node[^childIndex]
                  except KeyError, Exception:
                    ""
                checkEntity(nodeName = childName, line = $node.info.line,
                    options = options, oldResult = options.amount)
          # Check the node itself
          elif node.kind == nodeKind:
            checkEntity(nodeName = $node[0], line = $node.info.line,
                options = options, oldResult = options.amount)
        except KeyError, Exception:
          options.amount = errorMessage(
              text = "Error during checking hasEntity rule: ",
              e = getCurrentException())
          return
        # Check all children of the node with the rule
        for child in node.items:
          ruleCheck(astTree = child, options = options)
    if isParent:
      if options.ruleType == RuleTypes.count:
        message(text = (if getLogFilter() <
            lvlNotice: "D" else: options.fileName & ": d") & "eclared " &
            options.options[0] & " with name '" & options.options[1] &
            "' found: " & $options.amount, returnValue = options.amount,
                level = lvlNotice)
        options.amount = 1
      elif options.amount < 1:
        if not options.enabled and options.amount == 0:
          options.amount = 1
        elif options.negation:
          if options.ruleType == check:
            options.amount = 0
          else:
            message(text = (if getLogFilter() <
                lvlNotice: "D" else: options.fileName & ": d") &
                "oesn't have declared " & options.options[0] & " with name '" &
                options.options[1] & "'.", returnValue = options.amount,
                    level = lvlNotice, decrease = false)
            options.amount = 0
        else:
          message(text = (if getLogFilter() <
              lvlNotice: "D" else: options.fileName & ": d") &
              "oesn't have declared " & options.options[0] & " with name '" &
              options.options[1] & "'.", returnValue = options.amount, level = (
              if options.ruleType == check: lvlError else: lvlNotice))
          options.amount = 0

proc validateOptions*(options: seq[string]): bool {.contractual, raises: [],
    tags: [RootEffect].} =
  ## Validate the options entered from a configuration for the rule
  ##
  ## * options - the list of options entered from a configuration file
  ##
  ## Returns true if options are valid otherwise false.
  body:
    if options.len < 2:
      return errorMessage(text = "The rule hasEntity accepts two, three or four options, but not enough of them are supplied: '" &
          options.join(", ") & "'.").bool
    if options.len > 4:
      return errorMessage(text = "The rule hasEntity accepts two, three or four options, but too much of the are supplied: '" &
          options.join(", ") & "'.").bool
    let entityType: TNodeKind = parseEnum[TNodeKind](s = options[0],
        default = nkNone)
    if entityType == nkNone:
      return errorMessage(text = "The rule hasEntity the entity type has invalid value: '" &
          options[0] & "'.").bool
    if options.len > 2:
      let parentType: TNodeKind = parseEnum[TNodeKind](s = options[2],
          default = nkEmpty)
      if parentType == nkEmpty:
        return errorMessage(text = "The rule hasEntity the parent type has invalid value: '" &
            options[2] & "'.").bool
    if options.len > 3:
      let childIndex: int = try:
          options[3].parseInt()
        except ValueError:
          -1
      if childIndex < 0:
        return errorMessage(text = "The rule hasEntity the child index has invalid value: '" &
            options[3] & "'.").bool
    return true
