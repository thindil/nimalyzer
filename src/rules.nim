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

  OptionsTypesArray* = array[int, typedesc] ## The list of types of options for rules

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
    notFoundMessage: string; showForCheck: bool = false) {.sideEffect, raises: [],
    tags: [RootEffect], contractual.} =
  ## Show the rule summary info and update the rule result if needed
  ##
  ## * options         - the rule options set by the user and updated during
  ##                     checking the rule
  ## * foundMessage    - the message shown when rule type is count and the rule
  ##                     found something
  ## * notFoundMessage - the message shown when the rule doesn't found anything
  ## * showForCheck    - if true, show notFoundMessage for check type of rule,
  ##                     otherwise, don't show any message
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
        if options.ruleType != check or showForCheck:
          message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
              s = notFoundMessage) else: notFoundMessage),
              returnValue = options.amount,
              level = lvlNotice, decrease = false)
        options.amount = 0

proc setResult*(checkResult: bool; options: var RuleOptions; positiveMessage,
    negativeMessage: string) {.raises: [], tags: [RootEffect], contractual.} =
  ## Update the amount of the rule results
  ##
  ## * checkResult     - if true, the entity follow the check of the rule
  ## * options         - the options supplied to the rule
  ## * positiveMessage - the message shown when the entity meet the rule check
  ## * negativeMessage - the message shown when the entity not meet the rule check
  ##
  ## Returns updated amount of the rule results. It will be increased
  ## or decreased, depending on the rule settings.
  body:
    # The entity not meet rule's requirements
    if not checkResult:
      if options.negation and options.ruleType == check:
        options.amount.inc
        return
      if negativeMessage.len > 0:
        if options.ruleType == check:
          message(text = negativeMessage, returnValue = options.amount)
          options.amount = int.low
        else:
          if options.negation:
            message(text = negativeMessage, returnValue = options.amount,
                level = lvlNotice, decrease = false)
    # The enitity meet the rule's requirements
    else:
      if options.negation:
        if options.ruleType == check and positiveMessage.len > 0:
          message(text = positiveMessage, returnValue = options.amount)
        else:
          options.amount.dec
        return
      if options.ruleType == search and positiveMessage.len > 0:
        message(text = positiveMessage, returnValue = options.amount,
            level = lvlNotice, decrease = false)
      else:
        options.amount.inc

proc validateOptions*(ruleName: string; options: seq[string];
    optionsTypes: openArray[string]; allowedValues: openArray[string] = @[
        ]): bool {.raises: [], tags: [RootEffect], contractual.} =
  body:
    # Check if enough options entered
    if options.len < optionsTypes.len:
      return errorMessage(text = "The rule " & ruleName &
          " requires at least " & $optionsTypes.len & " options, but only " &
          $options.len & " provided: '" & options.join(", ") & "'").bool
    # Check if too much options entered
    if options.len > optionsTypes.len:
      return errorMessage(text = "The rule " & ruleName &
          " requires at maximum " & $optionsTypes.len & " options, but " &
          $options.len & " provided: '" & options.join(", ") & "'").bool
    # Check if all options have proper values
    for index, option in options.pairs:
      case optionsTypes[index]
      of "string":
        continue
      of "int":
        let intOption: int = try:
            options[index].parseInt()
          except ValueError:
            -1
        if intOption < 0:
          return errorMessage(text = "The rule " & ruleName &
              " option number " & $(index + 1) & "has invalid value: '" &
              option & "'.").bool
      of "TNodeKind":
        let entityType: TNodeKind = parseEnum[TNodeKind](s = option,
            default = nkEmpty)
        if entityType == nkEmpty:
          return errorMessage(text = "The rule " & ruleName &
              " option number " & $(index + 1) & "has invalid value: '" &
              option & "'.").bool
      of "custom":
        if option notin allowedValues:
          return errorMessage(text = "The rule " & ruleName &
              " option number " & $(index + 1) & "has invalid value: '" &
              option & "'.").bool
      else:
        return errorMessage(text = "The rule " & ruleName &
            " has declared unknown type of option: '" & optionsTypes[index] & "'.").bool
    return true
