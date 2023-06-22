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
import std/[logging, macros, os, strformat, strutils]
# External modules imports
import compiler/[ast, idents, renderer, trees]
import contracts
# Nimalyzer pragmas imports
import pragmas

# Export needed modules, so rules don't need to import them
export logging, strutils, ast, renderer, contracts, pragmas, os

type

  RuleTypes* = enum
    ## the types of the program's rules
    none, check, search, count, fix

  RuleOptionsTypes* = enum
    ## the available types of the program's rules' options
    integer, str, node, custom

  RuleOptions* = object
    ## Contains information for the program's rules
    ##
    ## * options         - The list of the program's rule
    ## * parent          - If true, check is currently make in the parent (usualy
    ##                     module) entity
    ## * fileName        - The path to the file which is checked
    ## * negation        - If true, the rule show return oposite result
    ## * ruleType        - The type of rule
    ## * amount          - The amount of results found by the rule
    ## * enabled         - If false, the rule is temporary disabled by pragmas
    ## * fixCommand      - The command executed by the rule if no custom code is set
    ##                     for fix type of rule
    ## * identsCache     - The Nim identifiers cache
    ## * forceFixCommand - If true, force the rule to use fixCommand instead of its
    ##                     fix code
    options*: seq[string]
    parent*: bool
    fileName*: string
    negation*: bool
    ruleType*: RuleTypes
    amount*: int
    enabled*: bool
    fixCommand*: string
    identsCache*: IdentCache
    forceFixCommand*: bool

  RuleSettings* = object
    ## Contains information about the program's rule configuration
    ##
    ## * name         - The name of the rule
    ## * checkProc    - The procedure used to check the rule
    ## * options      - The rule's options which can be set
    ## * optionValues - If the rule has option type custom, the values for the option
    ## * minOptions   - The minumal amount of options required by the rule
    ## * fixProc      - The procedure used to auto fix the rule
    name*: string
    checkProc*: proc (astNode, parentNode: PNode; rule: var RuleOptions)
    options*: seq[RuleOptionsTypes]
    optionValues*: seq[string]
    minOptions*: Natural
    fixProc*: proc (astNode, parentNode: PNode; rule: RuleOptions;
        data: string): bool

const availableRuleTypes*: array[4, string] = ["check", "search", "count", "fix"]
  ## The list of available types of the program rules

var rulesList2*: seq[RuleSettings] = @[]

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
      when defined(debug):
        message.add(y = "\nStack trace:\n" & getStackTrace(e = e))
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
              if oldState:
                log(level = lvlDebug, args = "Disabling rule: '" & ruleName &
                    "' at line: " & $node.info.line & ".")
              oldState = false
            else:
              if not oldState:
                log(level = lvlDebug, args = "Enabling rule: '" & ruleName &
                    "' at line: " & $node.info.line & ".")
              oldState = true
        except KeyError, Exception:
          discard

template setResult*(checkResult: bool; positiveMessage, negativeMessage: string;
    node: PNode; ruleData: string = ""; params: varargs[string]) =
  ## Update the amount of the rule results
  ##
  ## * checkResult     - if true, the entity follow the check of the rule
  ## * positiveMessage - the message shown when the entity meet the rule check
  ## * negativeMessage - the message shown when the entity not meet the rule check
  ## * node            - the AST node currently checked
  ## * ruleData        - an additional data, used by fix type of rules
  ## * params          - the list of texts which will be replaced in the
  ##                     positiveMessage and negativeMessage parameters
  ##
  ## Returns updated amount of the rule results. It will be increased
  ## or decreased, depending on the rule settings.
  var replacements: seq[(string, string)] = @[]
  for index, param in params:
    replacements.add(y = ("{params[" & $index & "]}", param))
  # The entity not meet rule's requirements
  if not checkResult:
    if rule.negation and rule.ruleType in {check, fix}:
      rule.amount.inc
    else:
      if negativeMessage.len > 0:
        if rule.ruleType in {check, fix}:
          message(text = messagePrefix & negativeMessage.multiReplace(
              replacements = replacements), returnValue = rule.amount)
          rule.amount = int.low
        else:
          if rule.negation:
            message(text = messagePrefix & negativeMessage.multiReplace(
                replacements = replacements), returnValue = rule.amount,
                level = lvlNotice, decrease = false)
      if rule.ruleType == fix:
        if ruleFix(astNode = node, parentNode = astNode, rule = rule,
            data = ruleData):
          rule.amount = int.low
        else:
          rule.amount = 1
  # The enitity meet the rule's requirements
  else:
    if rule.negation:
      if rule.ruleType in {check, fix} and positiveMessage.len > 0:
        message(text = messagePrefix & positiveMessage.multiReplace(
            replacements = replacements), returnValue = rule.amount)
      else:
        rule.amount.dec
      if rule.ruleType == fix:
        if ruleFix(astNode = node, parentNode = astNode, rule = rule,
            data = ruleData):
          rule.amount = int.low
        else:
          rule.amount = 1
    else:
      if rule.ruleType == search and positiveMessage.len > 0:
        message(text = messagePrefix & positiveMessage.multiReplace(
            replacements = replacements), returnValue = rule.amount,
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
          $options.len & " provided: '" & options.join(sep = ", ") & "'.").bool
    # Check if too much options entered
    if options.len > rule.options.len:
      return errorMessage(text = "The rule " & rule.name &
          " requires at maximum " & $rule.options.len & " options, but " &
          $options.len & " provided: '" & options.join(sep = ", ") & "'.").bool
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
        if option.toLowerAscii notin rule.optionValues:
          return errorMessage(text = "The rule " & rule.name &
              " option number " & $(index + 1) & " has invalid value: '" &
              option & "'.").bool
    return true

macro initCheck*(code: untyped): untyped =
  ## Initialize the check code for a rule, set some variables for the check and
  ## custom code in the main node of the code to check
  ##
  ## * code - the custom code which will be executed during initialization of
  ##          the check
  return nnkStmtList.newTree(children = [nnkLetSection.newTree(
      children = [nnkIdentDefs.newTree(children = [newIdentNode(i = "isParent"),
      newIdentNode(i = "bool"), nnkDotExpr.newTree(children = [newIdentNode(
      i = "rule"), newIdentNode(i = "parent")])]), nnkIdentDefs.newTree(
      children = [newIdentNode(i = "messagePrefix"), newIdentNode(i = "string"),
      nnkIfExpr.newTree(children = [nnkElifExpr.newTree(
      children = [nnkInfix.newTree(children = [newIdentNode(i = "<"),
      nnkCall.newTree(children = [newIdentNode(i = "getLogFilter")]),
      newIdentNode(i = "lvlNotice")]), nnkStmtList.newTree(children = newLit(
      s = ""))]), nnkElseExpr.newTree(children = nnkStmtList.newTree(
      children = [nnkInfix.newTree(children = [newIdentNode(i = "&"),
      nnkDotExpr.newTree(children = [newIdentNode(i = "rule"), newIdentNode(
      i = "fileName")]), newLit(s = ": ")])]))])])]), nnkIfStmt.newTree(
      children = nnkElifBranch.newTree(children = [newIdentNode(i = "isParent"),
      nnkStmtList.newTree(children = [nnkAsgn.newTree(
      children = [nnkDotExpr.newTree(children = [newIdentNode(i = "rule"),
      newIdentNode(i = "parent")]), newIdentNode(i = "false")]), code])]))])

template startCheck*(code: untyped): untyped =
  ## Run the custom code each time when the check for a node starts
  ##
  ## * code - the custom code which will be executed during starting of the
  ##          check
  setRuleState(node = astNode, ruleName = ruleSettings.name,
      oldState = rule.enabled)
  code

macro checking*(code: untyped): untyped =
  ## Run the check itself for the node and execute it for each child node of
  ## the node
  ##
  ## * code - the code of the check
  return nnkStmtList.newTree(children = [nnkForStmt.newTree(children = [
      newIdentNode(i = "node"), nnkDotExpr.newTree(children = [newIdentNode(
      i = "astNode"), newIdentNode(i = "items")]), nnkStmtList.newTree(
      children = [nnkCall.newTree(children = [newIdentNode(i = "setRuleState"),
      nnkExprEqExpr.newTree(children = [newIdentNode(i = "node"), newIdentNode(
      i = "node")]), nnkExprEqExpr.newTree(children = [newIdentNode(
      i = "ruleName"), nnkDotExpr.newTree(children = [newIdentNode(
      i = "ruleSettings"), newIdentNode(i = "name")])]), nnkExprEqExpr.newTree(
      children = [newIdentNode(i = "oldState"), nnkDotExpr.newTree(children = [
      newIdentNode(i = "rule"), newIdentNode(i = "enabled")])])]),
      nnkForStmt.newTree(children = [newIdentNode(i = "child"),
      nnkDotExpr.newTree(children = [newIdentNode(i = "node"), newIdentNode(
      i = "items")]), nnkStmtList.newTree(children = [nnkCall.newTree(
      children = [newIdentNode(i = "setRuleState"), nnkExprEqExpr.newTree(
      children = [newIdentNode(i = "node"), newIdentNode(i = "child")]),
      nnkExprEqExpr.newTree(children = [newIdentNode(i = "ruleName"),
      nnkDotExpr.newTree(children = [newIdentNode(i = "ruleSettings"),
      newIdentNode(i = "name")])]), nnkExprEqExpr.newTree(children = [
      newIdentNode(i = "oldState"), nnkDotExpr.newTree(children = [newIdentNode(
      i = "rule"), newIdentNode(i = "enabled")])])])])]), nnkIfStmt.newTree(
      children = [nnkElifBranch.newTree(children = [nnkDotExpr.newTree(
      children = [newIdentNode(i = "rule"), newIdentNode(i = "enabled")]),
      nnkStmtList.newTree(children = code)])]), nnkForStmt.newTree(children = [
      newIdentNode(i = "child"), nnkDotExpr.newTree(children = [newIdentNode(
      i = "node"), newIdentNode(i = "items")]), nnkStmtList.newTree(children = [
      nnkCall.newTree(children = [newIdentNode(i = "ruleCheck"),
      nnkExprEqExpr.newTree(children = [newIdentNode(i = "astNode"),
      newIdentNode(i = "child")]), nnkExprEqExpr.newTree(children = [
      newIdentNode(i = "parentNode"), newIdentNode(i = "astNode")]),
      nnkExprEqExpr.newTree(children = [newIdentNode(i = "rule"), newIdentNode(
      i = "rule")])])])])])])])

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
        if rule.ruleType in {check, fix}:
          rule.amount = 0
        else:
          message(text = (if messagePrefix.len > 0: messagePrefix else: "") &
              capitalizeAscii(s = notFoundMessage.fmt),
              returnValue = rule.amount, level = lvlNotice, decrease = false)
          rule.amount = 0
      else:
        if rule.ruleType notin {check, fix} or showForCheck:
          let messageLevel: Level = (if showForCheck: lvlError else: lvlNotice)
          message(text = (if messagePrefix.len > 0: messagePrefix else: "") &
              capitalizeAscii(s = notFoundMessage.fmt),
              returnValue = rule.amount, level = messageLevel, decrease = false)
        rule.amount = 0

macro checkRule*(code: untyped): untyped =
  ## Check the rule, add the procedure declaration and the check code itself
  ##
  ## * code - the code to run for check the rule
  return nnkStmtList.newTree(children = [nnkProcDef.newTree(children = [
      nnkPostfix.newTree(children = [newIdentNode(i = "*"), newIdentNode(
      i = "ruleCheck")]), newEmptyNode(), newEmptyNode(),
      nnkFormalParams.newTree(children = [newEmptyNode(), nnkIdentDefs.newTree(
      children = [newIdentNode(i = "astNode"), newIdentNode(i = "parentNode"),
      newIdentNode(i = "PNode"), newEmptyNode()]), nnkIdentDefs.newTree(
      children = [newIdentNode(i = "rule"), nnkVarTy.newTree(
      children = newIdentNode(i = "RuleOptions")), newEmptyNode()])]),
      nnkPragma.newTree(children = [nnkExprColonExpr.newTree(children = [
      newIdentNode(i = "raises"), nnkBracket.newTree()]),
      nnkExprColonExpr.newTree(children = [newIdentNode(
      i = "tags"), nnkBracket.newTree(children = newIdentNode(
      i = "RootEffect"))]), newIdentNode(i = "contractual")]), newEmptyNode(),
      nnkStmtList.newTree(children = code)])])

macro ruleConfig*(ruleName, ruleFoundMessage, ruleNotFoundMessage,
    rulePositiveMessage, ruleNegativeMessage: string; ruleOptions: seq[
    RuleOptionsTypes] = @[]; ruleOptionValues: seq[string] = @[];
    ruleMinOptions: int = 0; ruleShowForCheck: bool = false): untyped =
  ## Set the rule's settings, like name, options, etc
  ##
  ## * ruleName            - The name of the rule
  ## * rulefoundMessage    - The message shown when count type of the rule found
  ##                         something
  ## * rulenotFoundMessage - The message shown when count type of the rule not
  ##                         found anything
  ## * rulePositiveMessage - The message shown when the rule found element which
  ##                         follow the rule
  ## * ruleNegativeMessage - The message shown when the rule found element which
  ##                         doesn't follow the rule
  ## * ruleOptions         - The rule's options which can be set, default no options
  ## * ruleOptionValues    - If the rule has option type custom, the values for the
  ##                         option
  ## * ruleMinOptions      - The minumal amount of options required by the rule,
  ##                         default 0
  return nnkStmtList.newTree(children = [nnkProcDef.newTree(children = [
      nnkPostfix.newTree(children = [newIdentNode(i = "*"), newIdentNode(
      i = "ruleCheck")]), newEmptyNode(), newEmptyNode(),
      nnkFormalParams.newTree(children = [newEmptyNode(), nnkIdentDefs.newTree(
      children = [newIdentNode(i = "astNode"), newIdentNode(i = "parentNode"),
      newIdentNode(i = "PNode"), newEmptyNode()]), nnkIdentDefs.newTree(
      children = [newIdentNode(i = "rule"), nnkVarTy.newTree(children = [
      newIdentNode(i = "RuleOptions")]), newEmptyNode()])]), newEmptyNode(),
      newEmptyNode(), newEmptyNode()]), nnkStmtList.newTree(children = [
      nnkProcDef.newTree(children = [newIdentNode(i = "ruleFix"), newEmptyNode(),
      newEmptyNode(), nnkFormalParams.newTree(children = [newIdentNode(
      i = "bool"), nnkIdentDefs.newTree(children = [newIdentNode(i = "astNode"),
      newIdentNode(i = "parentNode"), newIdentNode(i = "PNode"), newEmptyNode()]),
      nnkIdentDefs.newTree(children = [newIdentNode(i = "rule"), newIdentNode(
      i = "RuleOptions"), newEmptyNode()]), nnkIdentDefs.newTree(children = [
      newIdentNode(i = "data"), newIdentNode(i = "string"), newEmptyNode()])]),
      newEmptyNode(), newEmptyNode(), newEmptyNode()])]), nnkLetSection.newTree(
      children = nnkIdentDefs.newTree(children = [nnkPostfix.newTree(
      children = [newIdentNode(i = "*"), newIdentNode(i = "ruleSettings")]),
      newIdentNode(i = "RuleSettings"), nnkObjConstr.newTree(children = [
      newIdentNode(i = "RuleSettings"), nnkExprColonExpr.newTree(children = [
      newIdentNode(i = "name"), ruleName]), nnkExprColonExpr.newTree(
      children = [newIdentNode(i = "checkProc"), newIdentNode(
      i = "ruleCheck")]), nnkExprColonExpr.newTree(children = [newIdentNode(
      i = "fixProc"), newIdentNode(i = "ruleFix")]), nnkExprColonExpr.newTree(
      children = [newIdentNode(i = "options"), ruleOptions]),
      nnkExprColonExpr.newTree(children = [newIdentNode(i = "optionValues"),
      ruleOptionValues]), nnkExprColonExpr.newTree(children = [newIdentNode(
      i = "minOptions"), ruleMinOptions])])])),
      nnkStmtList.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            newIdentNode("rulesList2"),
            newIdentNode("add")
          ),
          nnkExprEqExpr.newTree(
            newIdentNode("y"),
            newIdentNode("ruleSettings")
          )
        )
      ),
      nnkConstSection.newTree(
      children = [nnkConstDef.newTree(children = [newIdentNode(
      i = "showForCheck"), newIdentNode(i = "bool"), ruleShowForCheck]),
      nnkConstDef.newTree(children = [newIdentNode(i = "foundMessage"),
      newIdentNode(i = "string"), ruleFoundMessage]), nnkConstDef.newTree(
      children = [newIdentNode(i = "notFoundMessage"), newIdentNode(
      i = "string"), ruleNotFoundMessage]), nnkConstDef.newTree(children = [
      newIdentNode(i = "positiveMessage"), newIdentNode(i = "string"),
      rulePositiveMessage]), nnkConstDef.newTree(children = [newIdentNode(
      i = "negativeMessage"), newIdentNode(i = "string"),
      ruleNegativeMessage])])])

macro fixRule*(code: untyped): untyped =
  ## Run the code for fix the problem with the selected rule. If user doesn't
  ## specify the code to run or the rule was set to use fixCommand, execute
  ## the fixCommand.
  ##
  ## * code - the code which will be run to fix the problem
  let fixStatement: NimNode = nnkStmtList.newTree(children = [
      nnkStmtList.newTree(children = [nnkLetSection.newTree(children = [
      nnkIdentDefs.newTree(children = [newIdentNode(i = "fixCommand"),
      newEmptyNode(), nnkCall.newTree(children = [nnkDotExpr.newTree(
      children = [nnkDotExpr.newTree(children = [newIdentNode(i = "rule"),
      newIdentNode(i = "fixCommand")]), newIdentNode(i = "multiReplace")]),
      nnkExprEqExpr.newTree(children = [newIdentNode(i = "replacements"),
      nnkBracket.newTree(children = [nnkTupleConstr.newTree(children = [newLit(
      s = "{fileName}"), nnkDotExpr.newTree(children = [newIdentNode(
      i = "rule"), newIdentNode(i = "fileName")])]), nnkTupleConstr.newTree(
      children = [newLit(s = "{line}"), nnkPrefix.newTree(children = [
      newIdentNode(i = "$"), nnkDotExpr.newTree(children = [nnkDotExpr.newTree(
      children = [newIdentNode(i = "astNode"), newIdentNode(i = "info")]),
      newIdentNode(i = "line")])])])])])])])]), nnkIfStmt.newTree(children = [
      nnkElifBranch.newTree(children = [nnkPrefix.newTree(children = [
      newIdentNode(i = "not"), nnkPar.newTree(children = [nnkInfix.newTree(
      children = [newIdentNode(i = "=="), nnkCall.newTree(children = [
      newIdentNode(i = "execShellCmd"), newIdentNode(i = "fixCommand")]),
      newLit(i = 0)])])]), nnkStmtList.newTree(children = [
      nnkDiscardStmt.newTree(children = [nnkCall.newTree(children = [
      newIdentNode(i = "errorMessage"), nnkInfix.newTree(children = [
      newIdentNode(i = "&"), nnkInfix.newTree(children = [newIdentNode(i = "&"),
      newLit(s = "Can\'t execute command \'"), newIdentNode(i = "fixCommand")]),
      newLit(s = "\' for fix type of rule.")])])])])])])])])
  return nnkStmtList.newTree(children = [nnkProcDef.newTree(children = [
      newIdentNode(i = "ruleFix"), newEmptyNode(), newEmptyNode(),
      nnkFormalParams.newTree(children = [newIdentNode(i = "bool"),
      nnkIdentDefs.newTree(children = [newIdentNode(i = "astNode"),
      newIdentNode(i = "parentNode"), newIdentNode(i = "PNode"), newEmptyNode()]),
      nnkIdentDefs.newTree(children = [newIdentNode(i = "rule"), newIdentNode(
      i = "RuleOptions"), newEmptyNode()]), nnkIdentDefs.newTree(children = [
      newIdentNode(i = "data"), newIdentNode(i = "string"), newEmptyNode()])]),
      newEmptyNode(), newEmptyNode(), nnkStmtList.newTree(children =
    if code[0].kind == nnkDiscardStmt:
      fixStatement
    else:
      nnkStmtList.newTree(children = [nnkIfStmt.newTree(children = [
          nnkElifBranch.newTree(children = [nnkDotExpr.newTree(children = [
          newIdentNode(i = "rule"), newIdentNode(i = "forceFixCommand")]),
          fixStatement]), nnkElse.newTree(children = [code])])]))])])

proc getNodesToCheck*(parentNode, node: PNode): PNode {.raises: [], tags: [],
    contractual.} =
  ## Get the list of AST nodes to check by rule
  ##
  ## * parentNode - the parent AST node whichi will be searching for the node
  ## * node       - the AST node which will be looking for
  ##
  ## Returns the flattened list of nodes to check or nil if nothing found
  require:
    parentNode != nil
    node != nil
  body:
    for nodes in parentNode.items:
      for baseNode in nodes.items:
        if baseNode == node:
          return flattenStmts(n = parentNode)
        for child in baseNode.items:
          if child == node:
            return flattenStmts(n = nodes)
          for subChild in child.items:
            if subChild == node:
              return flattenStmts(n = baseNode)
