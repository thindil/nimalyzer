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
##   [ruleType] ?not? hasentity [entityType] [entityName]
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
##
## To look only for global entities, add `*` to the end of the entityName
## parameter. Setting it to *MyProc\** will look only for global entities
## which full name is MyProc.
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

# Standard library imports
import std/[logging, strutils]
# External modules imports
import compiler/[ast, renderer]
import contracts
# Internal modules imports
import ../rules

const ruleName* = "hasentity" ## The name of the rule used in a configuration file

proc ruleCheck*(astTree: PNode; options: RuleOptions): int {.contractual,
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
    options.options.len == 2
    options.fileName.len > 0
  body:
    let nodeKind = try:
          parseEnum[TNodeKind](s = options.options[0])
        except ValueError:
          nkNone
    if nodeKind == nkNone:
      message(text = "Invalid type of entity: " & options.options[0],
          returnValue = result, level = lvlFatal)
      return
    result = options.amount
    for node in astTree.items:
      for child in node.items:
        result = ruleCheck(astTree = child, options = RuleOptions(
            options: options.options, parent: false, fileName: options.fileName,
            negation: options.negation, ruleType: options.ruleType,
            amount: result))
      if node.kind != nodeKind:
        continue
      try:
        if startsWith(s = $node[0], prefix = options.options[1]):
          if options.negation:
            if options.ruleType == check:
              message(text = (if getLogFilter() <
                  lvlNotice: "H" else: options.fileName & ": h") &
                  "as declared " & options.options[0] & " with name '" &
                  options.options[1] & "' at line: " & $node.info.line & ".",
                  returnValue = result, decrease = false)
            else:
              result.inc
          else:
            if options.ruleType != search:
              result.inc
            else:
              message(text = (if getLogFilter() <
                  lvlNotice: "H" else: options.fileName & ": h") &
                  "as declared " & options.options[0] & " with name '" &
                  options.options[1] & "' at line: " & $node.info.line & ".",
                  returnValue = result, level = lvlNotice, decrease = false)
      except KeyError:
        continue
      except Exception:
        message(text = "Error during checking hasEntity rule: " &
            getCurrentExceptionMsg(), returnValue = result, level = lvlFatal)
        return
    if options.parent:
      if options.ruleType == RuleTypes.count:
        message(text = (if getLogFilter() <
            lvlNotice: "D" else: options.fileName & ": d") & "eclared " &
            options.options[0] & " with name '" & options.options[1] &
            "' found: " & $result, returnValue = result, level = lvlNotice)
        return 1
      if result < 1:
        if options.negation:
          if options.ruleType == check:
            return
          message(text = (if getLogFilter() <
              lvlNotice: "D" else: options.fileName & ": d") &
              "oesn't have declared " & options.options[0] & " with name '" &
              options.options[1] & "'.", returnValue = result,
                  level = lvlNotice, decrease = false)
          return
        message(text = (if getLogFilter() <
            lvlNotice: "D" else: options.fileName & ": d") &
            "oesn't have declared " & options.options[0] & " with name '" &
            options.options[1] & "'.", returnValue = result, level = (
            if options.ruleType == check: lvlError else: lvlNotice))

proc validateOptions*(options: seq[string]): bool {.contractual, raises: [],
    tags: [RootEffect].} =
  ## Validate the options entered from a configuration for the rule
  ##
  ## * options - the list of options entered from a configuration file
  ##
  ## Returns true if options are valid otherwise false.
  body:
    var tmpResult = 0
    if options.len < 2:
      message(text = "The rule hasEntity accepts exactly two options, but not enough of them are supplied: '" &
          options.join(", ") & "'.", returnValue = tmpResult, level = lvlFatal)
      return false
    if options.len > 2:
      message(text = "The rule hasEntity accepts exactly two options, but too much of the are supplied: '" &
          options.join(", ") & "'.", returnValue = tmpResult, level = lvlFatal)
      return false
    let entityType = parseEnum[TNodeKind](s = options[0], default = nkNone)
    if entityType == nkNone:
      message(text = "The rule hasEntity the entity type has invalid value: '" &
          options[0] & "'.", returnValue = tmpResult, level = lvlFatal)
      return false
    return true
