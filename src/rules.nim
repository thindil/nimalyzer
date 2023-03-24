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

## Provides various things for the program rules

# Standard library imports
import std/[logging, strutils]
# External modules imports
import compiler/[ast, renderer]
import contracts
# Nimalyzer pragmas imports
import pragmas

# Export needed modules, so rules don't need to import them
export logging, strutils, ast, renderer, contracts, pragmas

type

  RuleTypes* = enum
    ## the types of the program's rules
    none, check, search, count

  RuleOptions* = object   ## Contains information for the program's rules
    options*: seq[string] ## The list of the program's rule
    parent*: bool ## If true, check is currently make in the parent (usualy module) entity
    fileName*: string     ## The path to the file which is checked
    negation*: bool       ## If true, the rule show return oposite result
    ruleType*: RuleTypes  ## The type of rule
    amount*: int          ## The amount of results found by the rule
    enabled*: bool        ## If false, the rule is temporary disabled by pragmas

proc message*(text: string; returnValue: var int; level: Level = lvlError;
    decrease: bool = true) {.sideEffect, gcsafe, raises: [], tags: [RootEffect],
    contractual.} =
  ## Log the rule's selected message
  ##
  ## * text        - the messages which will be logged
  ## * returnValue - the value returned by the rule, increased or decreased
  ## * level       - the log level of the message. Default value is lvlError
  ## * decrease    - if true, decrease returnValue, otherwise increase it. The
  ##                 default value is true
  ##
  ## Returns the updated parameter returnValue
  require:
    text.len > 0
  body:
    if decrease:
      if returnValue > int.low:
        returnValue.dec
    else:
      returnValue.inc
    try:
      log(level = level, args = text)
    except Exception:
      echo "Can't log the message. Reason: ", getCurrentExceptionMsg()

proc errorMessage*(text: string; e: ref Exception = nil): int {.sideEffect,
    gcsafe, raises: [], tags: [RootEffect], contractual.} =
  ## Log the error message in the rule
  ##
  ## * text - the message which will be logged
  ## * e    - the exception which occured in a rule. Used to add information
  ##          to the message. Can be nil.
  ##
  ## The procedure always returns 0
  require:
    text.len > 0
  body:
    var message: string = text
    if e != nil:
      message.add(y = getCurrentExceptionMsg())
      {.ruleOff: "namedParams".}
      when defined(debug):
        {.ruleOn: "namedParams".}
        message.add(y = getStackTrace(e = e))
    try:
      log(level = lvlFatal, args = message)
    except Exception:
      echo "Can't log the message. Reason: ", getCurrentExceptionMsg()
    return 0

proc setRuleState*(node: PNode; ruleName: string;
    oldState: var bool) {.sideEffect, raises: [], tags: [RootEffect],
    contractual.} =
  ## Disable or enable again the rule for the selected Nim module if needed
  ##
  ## * node - the AST node to check for the state of the rule
  require:
    node != nil
  body:
    if node.kind == nkPragma:
      for child in node.items:
        try:
          let pragma: seq[string] = split(s = $child, sep = ": ")
          if pragma.len == 2 and pragma[1].toLowerAscii == "\"" &
              ruleName.toLowerAscii & "\"":
            if pragma[0].toLowerAscii == "ruleoff":
              oldState = false
              log(level = lvlDebug, args = "Disabling rule: '" & ruleName &
                  "' at line: " & $node.info.line & ".")
            else:
              oldState = true
              log(level = lvlDebug, args = "Enabling rule: '" & ruleName &
                  "' at line: " & $node.info.line & ".")
        except KeyError, Exception:
          discard

proc showSummary*(options: var RuleOptions; foundMessage,
    notFoundMessage: string) {.sideEffect, raises: [], tags: [RootEffect],
    contractual.} =
  ## Show the rule summary info and update the rule result if needed
  ##
  ## * options         - the rule options set by the user and updated during
  ##                     checking the rule
  ## * foundMessage    - the message shown when rule type is count and the rule
  ##                     found something
  ## * notFoundMessage - the message shown when the rule doesn't found anything
  ##
  ## Returns the updated parameter options
  require:
    foundMessage.len > 0
    notFoundMessage.len > 0
  body:
    if options.amount < 0:
      options.amount = 0
    if options.ruleType == RuleTypes.count:
      message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
          s = foundMessage) else: foundMessage) & " found: " & $options.amount,
          returnValue = options.amount, level = lvlNotice)
      options.amount = 1
    elif options.amount < 1:
      if not options.enabled and options.amount == 0:
        options.amount = 1
      elif options.negation:
        if options.ruleType == check:
          options.amount = 0
        else:
          message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
              s = notFoundMessage) else: notFoundMessage),
              returnValue = options.amount,
              level = lvlNotice, decrease = false)
          options.amount = 0
      else:
        message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
            s = notFoundMessage) else: notFoundMessage),
            returnValue = options.amount,
            level = lvlNotice, decrease = false)
        options.amount = 0
