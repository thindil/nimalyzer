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
import std/[logging, strformat, strutils]
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

  RuleOptionsTypes* = enum
    ## the available types of the program's rules' options
    integer, str, node, custom

  RuleOptions* = object   ## Contains information for the program's rules
    options*: seq[string] ## The list of the program's rule
    parent*: bool ## If true, check is currently make in the parent (usualy module) entity
    fileName*: string     ## The path to the file which is checked
    negation*: bool       ## If true, the rule show return oposite result
    ruleType*: RuleTypes  ## The type of rule
    amount*: int          ## The amount of results found by the rule
    enabled*: bool        ## If false, the rule is temporary disabled by pragmas

  RuleSettings* = object ## Contains information about the program's rule configuration
    name*: string                   ## The name of the rule
    checkProc*: proc (astNode: PNode; rule: var RuleOptions) ## The procedure used to check the rule
    options*: seq[RuleOptionsTypes] ## The rule's options which can be set
    optionValues*: seq[string] ## If the rule has option type custom, the values for the option
    minOptions*: Natural            ## The minumal amount of options required by the rule

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

proc showSummary*(rule: var RuleOptions; foundMessage,
    notFoundMessage: string; showForCheck: bool = false) {.sideEffect, raises: [],
    tags: [RootEffect], contractual.} =
  ## Show the rule summary info and update the rule result if needed
  ##
  ## * rule            - the rule options set by the user and updated during
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
    if rule.amount < 0:
      rule.amount = 0
    if rule.ruleType == RuleTypes.count:
      message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
          s = foundMessage) else: foundMessage) & " found: " & $rule.amount,
          returnValue = rule.amount, level = lvlNotice)
      rule.amount = 1
    elif rule.amount < 1:
      if not rule.enabled and rule.amount == 0:
        rule.amount = 1
      elif rule.negation:
        if rule.ruleType == check:
          rule.amount = 0
        else:
          message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
              s = notFoundMessage) else: notFoundMessage),
              returnValue = rule.amount,
              level = lvlNotice, decrease = false)
          rule.amount = 0
      else:
        if rule.ruleType != check or showForCheck:
          message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
              s = notFoundMessage) else: notFoundMessage),
              returnValue = rule.amount,
              level = lvlNotice, decrease = false)
        rule.amount = 0

proc setResult*(checkResult: bool; rule: var RuleOptions; positiveMessage,
    negativeMessage: string) {.raises: [], tags: [RootEffect], contractual.} =
  ## Update the amount of the rule results
  ##
  ## * checkResult     - if true, the entity follow the check of the rule
  ## * rule            - the rule's options supplied to the rule
  ## * positiveMessage - the message shown when the entity meet the rule check
  ## * negativeMessage - the message shown when the entity not meet the rule check
  ##
  ## Returns updated amount of the rule results. It will be increased
  ## or decreased, depending on the rule settings.
  body:
    # The entity not meet rule's requirements
    if not checkResult:
      if rule.negation and rule.ruleType == check:
        rule.amount.inc
        return
      if negativeMessage.len > 0:
        if rule.ruleType == check:
          message(text = negativeMessage, returnValue = rule.amount)
          rule.amount = int.low
        else:
          if rule.negation:
            message(text = negativeMessage, returnValue = rule.amount,
                level = lvlNotice, decrease = false)
    # The enitity meet the rule's requirements
    else:
      if rule.negation:
        if rule.ruleType == check and positiveMessage.len > 0:
          message(text = positiveMessage, returnValue = rule.amount)
        else:
          rule.amount.dec
        return
      if rule.ruleType == search and positiveMessage.len > 0:
        message(text = positiveMessage, returnValue = rule.amount,
            level = lvlNotice, decrease = false)
      else:
        rule.amount.inc

proc validateOptions*(rule: RuleSettings; options: seq[
    string]): bool {.raises: [], tags: [RootEffect], contractual.} =
  ## Validate the options entered from a configuration for the selected rule
  ##
  ## * rule     - the rule's settings for the selected rule, like name, options types, etc
  ## * options  - the list of options entered from a configuration file
  ##
  ## Returns true if the options are valid otherwise false.
  body:
    # Check if enough options entered
    if options.len < rule.minOptions:
      return errorMessage(text = "The rule " & rule.name &
          " requires at least " & $rule.minOptions & " options, but only " &
          $options.len & " provided: '" & options.join(", ") & "'.").bool
    # Check if too much options entered
    if options.len > rule.options.len:
      return errorMessage(text = "The rule " & rule.name &
          " requires at maximum " & $rule.options.len & " options, but " &
          $options.len & " provided: '" & options.join(", ") & "'.").bool
    # Check if all options have proper values
    for index, option in options.pairs:
      case rule.options[index]
      of str:
        continue
      of integer:
        let intOption: int = try:
            options[index].parseInt()
          except ValueError:
            -1
        if intOption < 0:
          return errorMessage(text = "The rule " & rule.name &
              " option number " & $(index + 1) & " has invalid value: '" &
              option & "'.").bool
      of node:
        let entityType: TNodeKind = parseEnum[TNodeKind](s = option,
            default = nkEmpty)
        if entityType == nkEmpty:
          return errorMessage(text = "The rule " & rule.name &
              " option number " & $(index + 1) & " has invalid value: '" &
              option & "'.").bool
      of custom:
        if option notin rule.optionValues:
          return errorMessage(text = "The rule " & rule.name &
              " option number " & $(index + 1) & " has invalid value: '" &
              option & "'.").bool
    return true

{.hint[Name]: off.}
template initCheck*(code: untyped): untyped =
  ## Initialize the check code for a rule, set some variables for the check and
  ## custom code in the main node of the code to check
  ##
  ## * code - the custom code which will be executed during initialization of
  ##          the check
  let
    isParent{.inject.}: bool = rule.parent
    messagePrefix{.inject.}: string = if getLogFilter() < lvlNotice:
          ""
        else:
          rule.fileName & ": "
  if isParent:
    rule.parent = false
    code
{.hint[Name]: on.}

template startCheck*(code: untyped): untyped =
  ## Run the custom code each time when the check for a node starts
  ##
  ## * code - the custom code which will be executed during starting of the
  ##          check
  setRuleState(node = astNode, ruleName = ruleSettings.name,
      oldState = rule.enabled)
  code

template checking*(code: untyped): untyped =
  ## Run the check itself for the node and execute it for each child node of
  ## the node
  ##
  ## * code - the code of the check
  for node{.inject.} in astNode.items:
    setRuleState(node = node, ruleName = ruleSettings.name,
        oldState = rule.enabled)
    for child in node.items:
      setRuleState(node = child, ruleName = ruleSettings.name,
          oldState = rule.enabled)
    code
    # Check each children of the current AST node with the rule
    for child in node.items:
      ruleCheck(astNode = child, rule = rule)

template endCheck*(code: untyped): untyped =
  ## Show the summary after the check and run the custom code if needed
  ##
  ## * code - the custom code which will be executed after checking the rule
  if isParent:
    code
    if rule.amount < 0:
      rule.amount = 0
    if rule.ruleType == RuleTypes.count:
      message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
          s = foundMessage.fmt) else: foundMessage.fmt) & " found: " &
          $rule.amount,
          returnValue = rule.amount, level = lvlNotice)
      rule.amount = 1
    elif rule.amount < 1:
      if not rule.enabled and rule.amount == 0:
        rule.amount = 1
      elif rule.negation:
        if rule.ruleType == check:
          rule.amount = 0
        else:
          message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
              s = notFoundMessage.fmt) else: notFoundMessage.fmt),
              returnValue = rule.amount,
              level = lvlNotice, decrease = false)
          rule.amount = 0
      else:
        if rule.ruleType != check or showForCheck:
          message(text = (if getLogFilter() < lvlNotice: capitalizeAscii(
              s = notFoundMessage.fmt) else: notFoundMessage.fmt),
              returnValue = rule.amount,
              level = lvlNotice, decrease = false)
        rule.amount = 0

template checkRule*(code: untyped): untyped =
  ## Check the rule, add the procedure declaration and the check code itself
  ##
  ## * code - the code to run for check the rule
  proc ruleCheck*(astNode{.inject.}: PNode;
      rule{.inject.}: var RuleOptions) {.raises: [], tags: [RootEffect],
          contractual, ruleOff: "paramsUsed", ruleOff: "hasDoc".} =
    code

template ruleConfig*(ruleName, ruleFoundMessage, ruleNotFoundMessage: string;
    ruleOptions: seq[RuleOptionsTypes] = @[]; ruleOptionValues: seq[string] = @[];
    ruleMinOptions: Natural = 0; ruleShowForCheck: bool = false): untyped =
  ## Set the rule's settings, like name, options, etc
  ##
  ## * ruleName            - The name of the rule
  ## * rulefoundMessage    - The message shown when count type of the rule found
  ##                         something
  ## * rulenotFoundMessage - The message shown when count type of the rule not
  ##                         found anything
  ## * ruleOptions         - The rule's options which can be set, default no options
  ## * ruleOptionValues    - If the rule has option type custom, the values for the
  ##                         option
  ## * ruleMinOptions      - The minumal amount of options required by the rule,
  ##                         default 0
  proc ruleCheck*(astNode{.inject.}: PNode;
      rule{.inject.}: var RuleOptions) {.ruleOff: "hasPragma".}
    ## Check recursively if the source code has the documentation in the proper
    ## locactions
    ##
    ## * astNode - The AST node representation of the Nim code to check
    ## * rule    - The rule options set by the user and the previous iterations
    ##             of the procedure

  let ruleSettings*{.inject.}: RuleSettings = RuleSettings(name: ruleName,
      checkProc: ruleCheck, options: ruleOptions,
      optionValues: ruleOptionValues,
      minOptions: ruleMinOptions) ## The rule settings like name, options, etc
  const
    showForCheck{.inject.}: bool = ruleShowForCheck ## If true, show summary for check type of the rule
    foundMessage{.inject.}: string = ruleFoundMessage ## The message shown when count type of the rule found something
    notFoundMessage{.inject.}: string = ruleNotFoundMessage ## The message shown when count type of the rule not found anything
