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

## The rule to check if all public declarations (variables, procedures, etc)
## have documentation comments
## The syntax in a configuration file is::
##
##   [ruleType] ?not? hasDoc
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a public declaration which doesn't have documentation.
##   Search type will list all public declarations which have documentation and
##   raise error if nothing was found. Count type will simply list the amount
##   of public declarations which have documentation.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about public declaration which have documentation.
##   Probably useable only with search and count type of rule.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "hasDoc"* in the element from which the rule
## should be disabled. For example, if the rule should be disabled for procedure
## `proc main()`, the full declaration of it should be::
##
##     proc main () {.ruleOff: "hasDoc".}
##
## To enable the rule again, the pragma *ruleOn: "hasDoc"* should be added in
## the element which should be checked. For example, if the rule should be
## re-enabled for `const a = 1`, the full declaration should be::
##
##     const a = 1 {.ruleOn: "hasDoc".}
##
## Examples
## --------
##
## 1. Check if all public declarations in module have documentation::
##
##     check hasDoc
##
## 2. Search for all public declarations which don't have documentation::
##
##     search not hasDoc

# Standard library imports
import std/[logging, strutils]
# External modules imports
import compiler/[ast, renderer]
import contracts
# Internal modules imports
import ../rules

const ruleName*: string = "hasdoc" ## The name of the rule used in a configuration file

proc ruleCheck*(astTree: PNode; options: var RuleOptions) {.contractual,
    raises: [], tags: [RootEffect].} =
  ## Check recursively if the source code has the documentation in the proper
  ## locactions
  ##
  ## * astTree - The AST tree representation of the Nim code to check
  ## * options - The rule options set by the user and the previous iterations
  ##             of the procedure
  ##
  ## The amount of result how many times the various elements of the Nim code
  ## has the documentation comments
  require:
    astTree != nil
    options.fileName.len > 0
  body:
    let isParent: bool = options.parent
    if isParent:
      options.parent = false
    let messagePrefix: string = if getLogFilter() < lvlNotice:
        ""
      else:
        options.fileName & ": "

    proc setResult(entityName, line: string; hasDoc: bool;
        options: var RuleOptions) {.raises: [], tags: [RootEffect],
        contractual.} =
      ## Update the amount of documentation found and log the message if needed
      ##
      ## * entityName - the name of the Nim's code entity which was checked for
      ##                the documentation comment
      ## * line       - the line in which the Nim's entity is in the source code
      ## * hasDoc     - if true, the entity has the documentation
      ## * options    - the options supplied to the rule
      ##
      ## Returns updated amount of documentation found. It will be increased
      ## or decreased, depending on the rule settings.
      require:
        entityName.len > 0
      body:
        if not options.enabled:
          return
        # Documentation not found
        if not hasDoc:
          if options.negation and options.ruleType == check:
            options.amount.inc
            return
          if options.ruleType == check:
            message(text = messagePrefix & entityName & (if line.len >
                0: " line: " & line else: "") & " doesn't have documentation.",
                returnValue = options.amount)
            options.amount = int.low
          else:
            if options.negation:
              message(text = messagePrefix & entityName & (if line.len >
                  0: " line: " & line else: "") &
                  " doesn't have documentation.", returnValue = options.amount,
                  level = lvlNotice, decrease = false)
        # Documentation found
        else:
          if options.negation:
            if options.ruleType == check:
              message(text = messagePrefix & entityName & (if line.len >
                  0: " line: " & line else: "") & " has documentation.",
                  returnValue = options.amount)
            else:
              options.amount.dec
          if options.ruleType == search:
            message(text = messagePrefix & entityName & (if line.len >
                0: " line: " & line else: "") & " has documentation.",
                returnValue = options.amount, level = lvlNotice,
                decrease = false)
          else:
            options.amount.inc

    if isParent:
      setResult(entityName = "Module", line = "",
          hasDoc = astTree.hasSubnodeWith(kind = nkCommentStmt),
          options = options)
    for node in astTree.items:
      # Check only elements which can have documentation
      if node.kind in {nkIdentDefs, nkProcDef, nkMethodDef, nkConverterDef,
          nkMacroDef, nkTemplateDef, nkIteratorDef, nkConstDef, nkTypeDef,
          nkEnumTy, nkConstSection, nkConstTy}:
        for child in node.items:
          if child.kind == nkPragma:
            setRuleState(node = child, ruleName = ruleName,
                oldState = options.enabled)
            break
        # Special check for constant declaration section
        if node.kind == nkConstSection:
          ruleCheck(astTree = node, options = options)
        else:
          # Set the name of the declared entity which is checked for documentation
          var declName: string = try:
                $node[0]
              except KeyError, Exception:
                ""
          if declName.len == 0:
            declName = try:
                $astTree[0]
              except KeyError, Exception:
                ""
          if declName.len == 0:
            options.amount = errorMessage(
                text = "Can't get the name of the declared entity.")
            return
          if declName.endsWith(suffix = "*") or node.kind in callableDefs:
            try:
              let hasDoc: bool = if node.kind in {nkEnumTy, nkIdentDefs,
                  nkConstDef, nkTemplateDef}:
                  node.comment.len > 0
                else:
                  node.hasSubnodeWith(kind = nkCommentStmt)
              setResult(entityName = "Declaration of " & declName,
                  line = $node.info.line, hasDoc = hasDoc, options = options)
            except KeyError as e:
              options.amount = errorMessage(
                  text = "Can't check the declared entity '" & declName & "'.", e = e)
              return
      # Check each children of the current AST node with the rule
      for child in node.items:
        ruleCheck(astTree = child, options = options)
    if isParent:
      if options.amount < 0:
        options.amount = 0
      if options.amount == 0 and options.ruleType == search:
        message(text = "The documentation not found.",
            returnValue = options.amount)
        options.amount = 0
      elif options.ruleType == RuleTypes.count:
        message(text = (if getLogFilter() <
            lvlNotice: "D" else: options.fileName & ": d") &
                "eclared public items with documentation found: " &
                    $options.amount,
                returnValue = options.amount, level = lvlNotice)
        options.amount = 1

proc validateOptions*(options: seq[string]): bool {.contractual, raises: [],
    tags: [RootEffect].} =
  ## Validate the options entered from a configuration for the rule
  ##
  ## * options - the list of options entered from a configuration file
  ##
  ## Returns true if options are valid otherwise false.
  body:
    if options.len > 0:
      return errorMessage(text = "The rule hasDoc doesn't accept any options, but options suplied: '" &
          options.join(", ") & "'.").bool
    return true
