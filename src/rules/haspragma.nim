# Copyright © 2023-2024 Bartek Jasicki
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
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check rule will
##   looking for procedures with declaration of the selected list of pragmas
##   and list all of them which doesn't have them, raising error either. Search
##   rule will look for the procedures with the selected pragmas and list
##   all of them which have the selected pragmas, raising error if nothing is
##   found.  Count type will simply list the amount of the procedures with the
##   selected pragmas. Fix type will try to append or remove the pragmas from
##   the list to procedures. Please read general information about the fix type
##   of rules about potential issues.
## * optional word *not* means negation for the rule. For example, if rule is
##   set to check for pragma SideEffect, adding word *not* will change
##   to inform only about procedures with that pragma.
## * haspragma is the name of the rule. It is case-insensitive, thus it can be
##   set as *haspragma*, *hasPragma* or *hAsPrAgMa*.
## * entityType is the type of code's entity which will be checked for the
##   selected pragmas. Possible values: `procedures`: check all procedures,
##   functions and methods. `templates`: check templates only. `all`: check
##   all routines declarations (procedures, functions, templates, macros, etc.).
##   `unborrowed`: check all procedures, functions and methods which are not
##   borrowed from other modules.
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
## should be disabled or in code before it. For example, if the rule should be
## disabled for procedure `main()`, the full declaration of it should be::
##
##      proc main() {.ruleOff: "hasPragma".}
##
## To enable the rule again, the pragma *ruleOn: "hasPragma"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `const a = 1`, the full declaration should
## be::
##
##      const a {.ruleOn: "hasPragma".} = 1
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

ruleConfig(ruleName = "haspragma",
  ruleFoundMessage = "declared procedures with{negation} selected pragmas",
  ruleNotFoundMessage = "The selected pragma(s) not found.",
  rulePositiveMessage = "procedure {params[0]} line: {params[1]} has declared pragma: {params[2]}.",
  ruleNegativeMessage = "procedure {params[0]} line: {params[1]} doesn't have declared pragma: {params[2]}.",
  ruleOptions = @[custom, str, str, str, str, str, str, str, str],
  ruleOptionValues = @["procedures", "templates", "all", "unborrowed"],
  ruleMinOptions = 2)

{.hint[XCannotRaiseY]: off.}
checkRule:
  initCheck:
    discard
  startCheck:
    let
      nodesToCheck: set[TNodeKind] = case rule.options[0]
        of "all":
          routineDefs
        of "procedures", "unborrowed":
          {nkProcDef, nkFuncDef, nkMethodDef}
        of "templates":
          {nkTemplateDef}
        else:
          {}
      negation: string = (if rule.negation: "out" else: "")
  checking:
    if node.kind in nodesToCheck:
      # Set the name of the procedure to check
      let
        pragmas: PNode = getDeclPragma(n = node)
        procName: string = try:
            $node[namePos]
          except KeyError, Exception:
            ""
      if procName.len == 0:
        rule.amount = errorMessage(
            text = "Can't get the name of the procedure.")
        return
      # The node doesn't have any pragmas
      if pragmas == nil:
        if rule.negation:
          if rule.ruleType == search:
            message(text = messagePrefix & "procedure " & procName &
                " line: " & $node.info.line &
                " doesn't have declared any pragmas.",
                returnValue = rule.amount, level = lvlNotice,
                decrease = false)
            rule.maxResults.dec
            if rule.maxResults == 0:
              return
          else:
            rule.amount.inc
        else:
          if rule.ruleType == check:
            message(text = messagePrefix & "procedure " & procName &
                " line: " & $node.info.line &
                " doesn't have declared any pragmas.",
                returnValue = rule.amount)
            rule.amount = int.low
            rule.maxResults.dec
            if rule.maxResults == 0:
              return
          else:
            if rule.ruleType == fix:
              for pragma in rule.options[1 .. ^1]:
                setResult(checkResult = false,
                    positiveMessage = positiveMessage,
                    negativeMessage = negativeMessage,
                    node = node,
                    ruleData = pragma, params = [
                    procName, $node.info.line, pragma])
            else:
              rule.amount.dec
      # Node has pragmas
      else:
        var strPragmas: seq[string] = @[]
        for pragma in pragmas:
          try:
            strPragmas.add(y = $pragma)
          except:
            discard
        if rule.options[0].toLowerAscii != "unborrowed" or "borrow" notin strPragmas:
          # Check the node for each selected pragma
          for pragma in rule.options[1 .. ^1]:
            if pragma[^1] == '*' and pragma[0] != '*':
              var hasPragma: bool = false
              for procPragma in strPragmas:
                if procPragma.startsWith(prefix = pragma[0..^2]):
                  hasPragma = true
                  break
              setResult(checkResult = hasPragma,
                  positiveMessage = positiveMessage,
                  negativeMessage = negativeMessage, node = node,
                  ruleData = pragma, params = [
                  procName, $node.info.line, pragma])
            elif pragma[0] == '*' and pragma[^1] != '*':
              var hasPragma: bool = false
              for procPragma in strPragmas:
                if procPragma.endsWith(suffix = pragma[1..^1]):
                  hasPragma = true
                  break
              setResult(checkResult = hasPragma,
                  positiveMessage = positiveMessage,
                  negativeMessage = negativeMessage, node = node,
                  ruleData = pragma, params = [
                  procName, $node.info.line, pragma])
            elif '*' in [pragma[0], pragma[^1]]:
              var hasPragma: bool = false
              for procPragma in strPragmas:
                if procPragma.contains(sub = pragma[1..^2]):
                  hasPragma = true
                  break
              setResult(checkResult = hasPragma,
                  positiveMessage = positiveMessage,
                  negativeMessage = negativeMessage, node = node,
                  ruleData = pragma, params = [
                  procName, $node.info.line, pragma])
            elif '*' notin [pragma[0], pragma[^1]] and pragma notin strPragmas:
              setResult(checkResult = false, positiveMessage = positiveMessage,
                  negativeMessage = negativeMessage, node = node,
                  ruleData = pragma, params = [
                  procName, $node.info.line, pragma])
            else:
              setResult(checkResult = true, positiveMessage = positiveMessage,
                  negativeMessage = negativeMessage, node = node,
                  ruleData = pragma, params = [
                  procName, $node.info.line, pragma])
  endCheck:
    if not rule.enabled and rule.amount == 0:
      rule.amount = 1
      return
{.hint[XCannotRaiseY]: on.}

fixRule:
  var pragmas: PNode = astNode[pragmasPos]
  # Remove the selected pragma from the declaration
  if rule.negation:
    for index, node in pragmas:
      try:
        let pragma: string = $node
        if '*' notin [data[0], data[^1]] and pragma == data:
          delSon(father = pragmas, idx = index)
          result = true
          break
        elif data[^1] == '*' and data[0] != '*' and pragma.startsWith(
            prefix = data[0..^2]):
          delSon(father = pragmas, idx = index)
          result = true
          break
        elif data[0] == '*' and data[^1] != '*' and pragma.endsWith(
            suffix = data[1..^1]):
          delSon(father = pragmas, idx = index)
          result = true
          break
        elif '*' in [data[0], data[^1]] and pragma.contains(sub = data[1..^2]):
          delSon(father = pragmas, idx = index)
          result = true
          break
      except KeyError, Exception:
        discard errorMessage(text = "Can't remove the selected pragma(s). Reason: " &
            getCurrentExceptionMsg())
        return false
    if pragmas.len == 0:
      for index, child in astNode:
        if child == pragmas:
          astNode[index] = newNode(kind = nkEmpty)
          result = true
          break
  # Add the selected pramga to the declaration
  else:
    if pragmas.kind == nkEmpty:
      astNode[pragmasPos] = newNode(kind = nkPragma)
      pragmas = astNode.getDeclPragma
    if not data.contains(chars = {'['}):
      pragmas.sons.add(y = newIdentNode(ident = getIdent(ic = rule.identsCache,
          identifier = data), info = pragmas.info))
      return true
    elif not data.contains(chars = {'*'}):
      let
        startIndex: int = data.find(chars = {'['})
        endIndex: int = data.find(chars = {']'})
        pragmaName: string = data[0 .. data.find(chars = {':'}) - 1]
        newPragma: PNode = newTree(kind = nkExprColonExpr, children = [])
        values: PNode = newTree(kind = nkBracket, children = [])
      newPragma.sons.add(y = newIdentNode(ident = getIdent(
          ic = rule.identsCache, identifier = pragmaName), info = (if pragmas ==
              nil: astNode.info else: pragmas.info)))
      for value in data[startIndex + 1 .. endIndex - 1].split(sep = ','):
        if value.len == 0:
          continue
        values.sons.add(y = newIdentNode(ident = getIdent(ic = rule.identsCache,
            identifier = value), info = pragmas.info))
      newPragma.sons.add(y = values)
      if pragmas == nil:
        astNode[pragmasPos] = newPragma
      else:
        pragmas.sons.add(y = newPragma)
      return true
