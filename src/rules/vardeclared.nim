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

## The rule to check if the selected variable declaration (var, let and const)
## has declared type and or value
## The syntax in a configuration file is::
##
##   [ruleType] ?not? varDeclared [declarationType]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a declaration isn't in desired pattern. Search type
##   will list all declarations with desired pattern and raise error if
##   nothing was found. Count type will simply list the amount of declarations
##   with the desired pattern.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about procedures without desired pattern.
##   Probably useable only with search and count type of rule.
## * declarationType is the desired type of variable's declaration to check.
##   Possible values are: full - the declaration must have declared type and
##   value for the variable, type - the declaration must have declared type for
##   the variable, value - the declaration must have declared value for the
##   variable.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "varDeclared"* before the block of code from which
## the rule should be disabled. For example, if the rule should be disabled for
## variable## `var a: int`, the full declaration of it should be::
##
##      {.ruleOff: "varDeclared".}
##      var a: int
##
## To enable the rule again, the pragma *ruleOn: "varDeclared"* should be added
## before the declaration which should be checked. For example, if the rule
## should be re-enabled for variable `let b = 2`, the full declaration should
## be::
##
##      {.ruleOn: "varDeclared".}
##      let b = 2
##
## Examples
## --------
##
## 1. Check if all declarations have set type and value for them::
##
##     check varDeclared full
##
## 2. Search for all declarations which don't set type for them::
##
##     search not varDeclared type

# Import default rules' modules
import ../rules

const ruleName*: string = "vardeclared" ## The name of the rule used in a configuration file

proc ruleCheck*(astTree: PNode; options: var RuleOptions) {.contractual,
    raises: [], tags: [RootEffect].} =
  ## Check recursively if all variables' declarations in Nim code follow
  ## the selected pattern
  ##
  ## * astTree - The AST tree representation of the Nim code to check
  ## * options - The rule options set by the user and the previous iterations
  ##             of the procedure
  ##
  ## The amount of result how many declarations of variables follow the
  ## selected pattern
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

    proc checkDeclaration(declaration: PNode; options: var RuleOptions;
        index: Positive; identType: string) {.contractual, raises: [], tags: [RootEffect].} =
      ## Check if the declaration of a variable has defined the selected
      ## part: type or value.
      ##
      ## * declaration - the declaration of a variable to check
      ## * options     - the options supplied to the rule
      ## * index       - the index of the declaration's element to check, 1 for
      ##                 type, 2 for value
      ## * identType   - the name of the declaration's element to check, "type"
      ##                 or "value"
      ##
      ## Returns updated amount of declarations which fullfil the rule. It will
      ## be increased or decreased, depending on the rule settings.
      require:
        declaration != nil
        options.options.len > 0
      body:
        try:
          if declaration[index].kind == nkEmpty:
            if not options.negation:
              if options.ruleType == check:
                message(text = messagePrefix & "declaration of '" &
                    $declaration[0] &
                  "' line: " & $declaration.info.line &
                  " doesn't set " & identType & " for the variable.",
                      returnValue = options.amount)
                options.amount = int.low
            else:
              if options.ruleType == search:
                message(text = messagePrefix & "declaration of '" &
                    $declaration[0] &
                  "' line: " & $declaration.info.line &
                  " doesn't set " & identType & " for the variable.",
                  returnValue = options.amount, level = lvlNotice,
                  decrease = false)
              else:
                options.amount.inc
          else:
            if options.negation:
              if options.ruleType == check:
                message(text = messagePrefix & "declaration of " &
                    $declaration[0] &
                  " line: " &
                  $declaration.info.line & " sets the " & identType & " '" &
                      $declaration[index] & "' as the " & identType &
                          " of the variable.",
                  returnValue = options.amount)
                options.amount = int.low
              elif options.ruleType == RuleTypes.count:
                options.amount.dec
            else:
              if options.ruleType == search:
                message(text = messagePrefix & "declaration of " &
                    $declaration[0] &
                  " line: " &
                  $declaration.info.line & " sets the " & identType & " '" &
                      $declaration[index] & "' as the " & identType &
                          " of the variable.",
                  returnValue = options.amount, level = lvlNotice,
                      decrease = false)
              else:
                options.amount.inc
        except KeyError, Exception:
          options.amount = errorMessage(text = messagePrefix &
              "can't check declaration of variable " &
              " line: " &
              $declaration.info.line & ". Reason: ", e = getCurrentException())

    for node in astTree.items:
      # Check the node if rule is enabled
      setRuleState(node = node, ruleName = ruleName,
          oldState = options.enabled)
      if options.enabled:
        # Sometimes the compiler detects declarations as children of the node
        if node.kind in {nkVarSection, nkLetSection, nkConstSection}:
          # Check each variable declaration if meet the rule requirements
          for declaration in node.items:
            # Check if declaration of variable sets its type
            if options.options[0] in ["full", "type"]:
              checkDeclaration(declaration = declaration, options = options,
                  index = 1, identType = "type")
            # Check if declaration of variable sets its value
            if options.options[0] in ["full", "value"]:
              checkDeclaration(declaration = declaration, options = options,
                  index = 2, identType = "value")
        # And sometimes the compiler detects declarations as the node
        elif node.kind == nkIdentDefs and astTree.kind in {nkVarSection,
            nkLetSection, nkConstSection}:
          # Check if declaration of variable sets its type
          if options.options[0] in ["full", "type"]:
            checkDeclaration(declaration = node, options = options,
                index = 1, identType = "type")
          # Check if declaration of variable sets its value
          if options.options[0] in ["full", "value"]:
            checkDeclaration(declaration = node, options = options,
                index = 2, identType = "value")
      # Check the node's children with the rule
      for child in node.items:
        ruleCheck(astTree = child, options = options)
    if isParent:
      if options.amount < 0:
        options.amount = 0
      if options.ruleType == RuleTypes.count:
        message(text = (if getLogFilter() <
            lvlNotice: "D" else: options.fileName & ": d") &
            "eclarations with" & (if options.negation: "out" else: "") &
            " " & options.options[0] & " declaration found: " & $options.amount,
                returnValue = options.amount,
            level = lvlNotice)
        options.amount = 1

proc validateOptions*(options: seq[string]): bool {.contractual, raises: [],
    tags: [RootEffect].} =
  ## Validate the options entered from a configuration for the rule
  ##
  ## * options - the list of options entered from a configuration file
  ##
  ## Returns true if options are valid otherwise false.
  body:
    if options.len == 0:
      return errorMessage(text = "The rule varDeclared require type of declaration as the option, but nothing was supplied.").bool
    elif options.len == 1 and options[0] notin ["full", "type", "value"]:
      return errorMessage(text = "The rule varDeclared require 'full', 'type' or 'value' as option, but suplied option was: '" &
          options[0] & "'.").bool
    elif options.len > 1:
      return errorMessage(text = "The rule varDeclared require exactly one option, but more options suplied: '" &
          options.join(", ") & "'.").bool
    return true
