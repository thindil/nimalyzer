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

## The rule to check if the selected procedure has the selected pragma. The
## syntax in a configuration file is::
##
##   [ruleType] ?not? haspragma [entityType] [listOfPragmas]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check rule will
##   looking for procedures with declaration of the selected list of pragmas
##   and list all of them which doesn't have them, raising error either. Search
##   rule will look for the procedures with the selected pragmas and list
##   all of them which have the selected pragmas, raising error if nothing is
##   found.  Count type will simply list the amount of the procedures with the
##   selected pragmas.
## * optional word *not* means negation for the rule. For example, if rule is
##   set to check for pragma SideEffect, adding word *not* will change
##   to inform only about procedures with that pragma.
## * haspragma is the name of the rule. It is case-insensitive, thus it can be
##   set as *haspragma*, *hasPragma* or *hAsPrAgMa*.
## * entityType is the type of code's entity which will be checked for the
##   selected pragmas. Possible values: `procedures`: check all procedures,
##   functions and methods. `templates`: check templates only. `all`: check
##   all routines declarations (procedures, functions, templates, macros, etc.).
## * listOfPragmas is the list of pragmas for which the rule will be looking
##   for. Each pragma must be separated with whitespace, like::
##
##     SideEffect gcSafe
##
## It is possible to use shell's like globing in setting the names of the
## pragmas. If the sign `*` is at the start of the pragma name, it means to
## look for procedures which have pragmas ending with that string. For example,
## `*Effect` will find procedures with pragma *SideEffect* but not
## *sideeffect* or *effectPragma*. If sign `*` is at the end of the pragma
## name, it means to look for procedures which have pragmas starting
## with that string. For example, `raises: [*` will find procedures with
## pragma *raises: []* or *raises: [Exception]* but not `myCustomraises: [custom]`.
## If the name of the pragma starts and ends with sign `*`, it means to look
## for procedures which have pragmas containing the string. For example, `*Exception*`
## will find `raises: [MyException]` or `myCustomExceptionRaise`.
##
## The list of pragmas must be in the form of console line arguments:
##
## 1. Each pragma name must be separated with whitespace: `myPragma otherPragma`
## 2. If the search string contains whitespace, it must be enclosed in quotes
##    or escaped, like in the console line arguments: `"mypragma: [" otherPragma`
## 3. All other special characters must be escaped as in a console line
##    arguments: `stringWith\"QuoteSign`
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "hasPragma"* in the element from which the rule
## should be disabled. For example, if the rule should be disabled for procedure
## `main()`, the full declaration of it should be::
##
##      proc main() {.ruleOff: "hasPragma".}
##
## To enable the rule again, the pragma *ruleOn: "hasPragma"* should be added in
## the element which should be checked. For example, if the rule should be
## re-enabled for `const a = 1`, the full declaration should be::
##
##      const a = 1 {.ruleOn: "hasPragma".}
##
## Examples
## --------
##
## 1. Check if all procedures have declared pragma raises. It can be empty or
##    contains names of raised exception::
##
##      check hasPragma procedures "raises: [*"
##
## 2. Find all declarations with have *sideEffect* pragma declared::
##
##      search hasPragma all sideEffect
##
## 3. Count amount of procedures which don't have declared pragma *gcSafe*::
##
##      count not hasPragma procedures gcSafe
##
## 4. Check if all procedures have declared pragmas *contractual* and *lock*.
##    The *lock* pragma must have entered the level of the lock::
##
##      check hasPragma procedures contractual "lock: *"

# Import default rules' modules
import ../rules

const
  ruleName*: string = "haspragma" ## The name of the rule used in a configuration file
  ruleOptions*: seq[RuleOptionsTypes] = @[custom, RuleOptionsTypes.string,
      RuleOptionsTypes.string, RuleOptionsTypes.string, RuleOptionsTypes.string,
      RuleOptionsTypes.string, RuleOptionsTypes.string, RuleOptionsTypes.string,
      RuleOptionsTypes.string] ## The list of options required by the rule
  ruleOptionValues*: seq[string] = @["procedures", "templates",
      "all"]                   ## The list of custom option values for the rule
  ruleMinOptions*: Natural = 2 ## The minimum amount of options required by the rule

proc ruleCheck*(astTree: PNode; options: var RuleOptions) {.contractual,
    raises: [], tags: [RootEffect].} =
  ## Check recursively if the Nim code entities have proper pragmas.
  ##
  ## * astTree - The AST tree representation of the Nim code to check
  ## * options - The rule options set by the user and the previous iterations
  ##             of the procedure
  ##
  ## The amount of result how many times the various elements of the Nim code
  ## has the proper pragmas
  require:
    astTree != nil
    options.options.len > 0
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

    proc setResult(procName, line, pragma: string; hasPragma: bool;
        options: var RuleOptions) {.raises: [], tags: [RootEffect],
        contractual.} =
      ## Update the amount of pragmas found and log the message if needed
      ##
      ## * procName - the name of the Nim's code entity which was checked for
      ##                the pragma
      ## * line       - the line in which the Nim's entity is in the source code
      ## * hasPragma  - if true, the entity has the pragma
      ## * options    - the rule options set by the user and the previous iterations
      ##                 of the procedure
      ##
      ## Returns the updated parameter options.
      require:
        procName.len > 0
        line.len > 0
        pragma.len > 0
      body:
        if not options.enabled:
          return
        setResult(checkResult = hasPragma, options = options,
            positiveMessage = messagePrefix & "procedure " & procName &
            " line: " & line & " has declared pragma: " & pragma & ".",
            negativeMessage = messagePrefix & "procedure " & procName &
            " line: " & line & " doesn't have declared pragma: " & pragma & ".")

    for node in astTree.items:
      # Check the node's children with the rule
      # The node can have pragma, check it
      if node.kind in nodesToCheck:
        for child in node.items:
          if child.kind == nkPragma:
            setRuleState(node = child, ruleName = ruleName,
                oldState = options.enabled)
            break
        # Set the name of the procedure to check
        let
          pragmas: PNode = getDeclPragma(n = node)
          procName: string = try:
              $node[0]
            except KeyError, Exception:
              ""
        if procName.len == 0:
          options.amount = errorMessage(
              text = "Can't get the name of the procedure.")
          return
        # The node doesn't have any pragmas
        if pragmas == nil:
          if not options.negation:
            if options.ruleType == check:
              message(text = messagePrefix & "procedure " & procName &
                  " line: " & $node.info.line &
                  " doesn't have declared any pragmas.",
                  returnValue = options.amount)
              options.amount = int.low
            else:
              options.amount.dec
          else:
            if options.ruleType == search:
              message(text = messagePrefix & "procedure " & procName &
                  " line: " & $node.info.line &
                  " doesn't have declared any pragmas.",
                  returnValue = options.amount, level = lvlNotice,
                  decrease = false)
            else:
              options.amount.inc
        else:
          var strPragmas: seq[string] = @[]
          for pragma in pragmas:
            try:
              strPragmas.add(y = $pragma)
            except KeyError, Exception:
              discard
          # Check the node for each selected pragma
          for pragma in options.options[1 .. ^1]:
            if '*' notin [pragma[0], pragma[^1]] and pragma notin strPragmas:
              setResult(procName = procName, line = $node.info.line,
                  pragma = pragma, hasPragma = false, options = options)
            elif pragma[^1] == '*' and pragma[0] != '*':
              var hasPragma: bool = false
              for procPragma in strPragmas:
                if procPragma.startsWith(prefix = pragma[0..^2]):
                  hasPragma = true
                  break
              setResult(procName = procName, line = $node.info.line,
                  pragma = pragma, hasPragma = hasPragma, options = options)
            elif pragma[0] == '*' and pragma[^1] != '*':
              var hasPragma: bool = false
              for procPragma in strPragmas:
                if procPragma.endsWith(suffix = pragma[1..^1]):
                  hasPragma = true
                  break
              setResult(procName = procName, line = $node.info.line,
                  pragma = pragma, hasPragma = hasPragma, options = options)
            elif '*' in [pragma[0], pragma[^1]]:
              var hasPragma: bool = false
              for procPragma in strPragmas:
                if procPragma.contains(sub = pragma[1..^2]):
                  hasPragma = true
                  break
              setResult(procName = procName, line = $node.info.line,
                  pragma = pragma, hasPragma = hasPragma, options = options)
            else:
              setResult(procName = procName, line = $node.info.line,
                  pragma = pragma, hasPragma = true, options = options)
      for child in node.items:
        ruleCheck(astTree = child, options = options)
    if isParent:
      if not options.enabled and options.amount == 0:
        options.amount = 1
        return
      showSummary(options = options, foundMessage = "declared procedures with selected pragmas",
          notFoundMessage = "The selected pragma(s) not found.")

proc validateOptions*(options: seq[string]): bool {.contractual, raises: [],
    tags: [RootEffect].} =
  ## Validate the options entered from a configuration for the rule
  ##
  ## * options - the list of options entered from a configuration file
  ##
  ## Returns true if options are valid otherwise false.
  body:
    if options.len < 1:
      return errorMessage(text = "The rule hasPragma require type of entities to check and name(s) of pragma(s) as the option, but nothing was supplied.").bool
    if options.len == 1:
      return errorMessage(text = "The rule hasPragma require type of entities to check and name(s) of pragma(s) as the option, but only one option was supplied.").bool
    if options[0] notin ["procedures", "templates", "all"]:
      return errorMessage(text = "The first option of the rule hasPragma must be type of enties to check, but got: '" &
          options[0] & "'.").bool
    return true
