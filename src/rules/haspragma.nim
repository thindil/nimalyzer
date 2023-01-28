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
##   [ruleType] ?not? haspragma [listOfPragmas]
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
## Examples
## --------
##
## 1. Check if all procedures have declared pragma raises. It can be empty or
##    contains names of raised exception::
##
##      check hasPragma "raises: [*"
##
## 2. Find all procedures with have *sideEffect* pragma declared::
##
##      search hasPragma sideEffect
##
## 3. Count amount of procedures which don't have declared pragma *gcSafe*::
##
##      count not hasPragma gcSafe
##
## 4. Check if all procedures have declared pragmas *contractual* and *lock*.
##    The *lock* pragma must have entered the level of the lock::
##
##      check hasPragma contractual "lock: *"

# Standard library imports
import std/[logging, strutils]
# External modules imports
import compiler/[ast, renderer]
import contracts
# Internal modules imports
import ../rules

const ruleName* = "haspragma"

proc ruleCheck*(astTree: PNode; options: RuleOptions): int {.contractual,
    raises: [], tags: [RootEffect].} =
  require:
    astTree != nil
    options.options.len > 0
    options.fileName.len > 0
  body:
    result = options.amount
    let messagePrefix = if getLogFilter() < lvlNotice:
        ""
      else:
        options.fileName & ": "

    proc setResult(procName, line, pragma: string; hasPragma: bool;
        oldResult: var int) {.raises: [], tags: [RootEffect], contractual.} =
      require:
        procName.len > 0
        line.len > 0
        pragma.len > 0
      body:
        if not hasPragma:
          if options.negation and options.ruleType == check:
            return
          if options.ruleType == check:
            message(text = messagePrefix & "procedure " & procName & " line: " &
                line & " doesn't have declared pragma: " & pragma & ".",
                returnValue = oldResult)
          else:
            if options.negation:
              message(text = messagePrefix & "procedure " & procName &
                  " line: " & line & " doesn't have declared pragma: " &
                  pragma & ".", returnValue = oldResult, level = lvlNotice,
                  decrease = false)
        else:
          if options.negation:
            if options.ruleType == check:
              message(text = messagePrefix & "procedure " & procName &
                  " line: " & line & " has declared pragma: " & pragma & ".",
                  returnValue = oldResult)
            else:
              oldResult.dec
          if options.ruleType == search:
            message(text = messagePrefix & "procedure " & procName & " line: " &
                line & " has declared pragma: " & pragma & ".",
                returnValue = oldResult, level = lvlNotice, decrease = false)
          else:
            oldResult.inc

    for node in astTree.items:
      for child in node.items:
        result = ruleCheck(astTree = child, options = RuleOptions(
            options: options.options, parent: false,
            fileName: options.fileName, negation: options.negation,
            ruleType: options.ruleType, amount: result))
      if node.kind notin routineDefs:
        continue
      let
        pragmas = getDeclPragma(n = node)
        procName = try:
            $node[0]
          except KeyError, Exception:
            ""
      if procName.len == 0:
        message(text = "Can't get the name of the procedure.", level = lvlFatal,
            returnValue = result)
        result.inc
        return
      if pragmas == nil:
        if not options.negation:
          if options.ruleType == check:
            message(messagePrefix & "procedure " & procName & " line: " &
                $node.info.line & " doesn't have declared any pragmas.",
                returnValue = result)
          else:
            result.dec
        else:
          if options.ruleType == search:
            message(messagePrefix & "procedure " & procName & " line: " &
                $node.info.line & " doesn't have declared any pragmas.",
                returnValue = result, level = lvlNotice, decrease = false)
          else:
            result.inc
        continue
      var strPragmas: seq[string]
      for pragma in pragmas:
        try:
          strPragmas.add(y = $pragma)
        except KeyError, Exception:
          discard
      for pragma in options.options:
        if '*' notin [pragma[0], pragma[^1]] and pragma notin strPragmas:
          setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = false, oldResult = result)
        elif pragma[^1] == '*' and pragma[0] != '*':
          var hasPragma = false
          for procPragma in strPragmas:
            if procPragma.startsWith(prefix = pragma[0..^2]):
              hasPragma = true
              break
          setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = hasPragma, oldResult = result)
        elif pragma[0] == '*' and pragma[^1] != '*':
          var hasPragma = false
          for procPragma in strPragmas:
            if procPragma.endsWith(suffix = pragma[1..^1]):
              hasPragma = true
              break
          setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = hasPragma, oldResult = result)
        elif '*' in [pragma[0], pragma[^1]]:
          var hasPragma = false
          for procPragma in strPragmas:
            if procPragma.contains(sub = pragma[1..^2]):
              hasPragma = true
              break
          setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = hasPragma, oldResult = result)
        else:
          setResult(procName = procName, line = $node.info.line,
              pragma = pragma, hasPragma = true, oldResult = result)
    if options.parent:
      if result == 0 and options.ruleType == search:
        message(text = "The selected pragma(s) not found.",
            returnValue = result)
        return 0
      if options.ruleType == RuleTypes.count:
        message(text = (if getLogFilter() <
            lvlNotice: "D" else: options.fileName & ": d") &
                "eclared procedures with selected pragmas found: " & $result,
                returnValue = result, level = lvlNotice)
        return 1
