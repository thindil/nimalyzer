# Copyright © 2024-2026 Bartek thindil Jasicki
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

## The rule to check do object's types' declarations in the code contains or not some
## expressions. Checked things:
##
## * Do the object's type's declaration contains public fields.
## * Do the object's type's declaration contains fields with type of int or string.
## * Do the object's type has declared a constructor.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? objects [checkType]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is an object's type's declaration which violates the check.
##   Search type will list all declarations which violates the check or raise an
##   error if nothing found. Count type will simply list the amount of the
##   declarations which violates the check. Fix type will add or remove public mark
##   `*` from fields' of the object's type's declaration but only when **checkType**
##   is set to *publicfields*.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about objects' types' declarations which have only
##   private fields.
## * objects is the name of the rule. It is case-insensitive, thus it can be
##   set as *objects*, *objects* or *oBjEcTs*.
## * checkType is the type of checks to perform on the objects' declarations. Proper
##   values are: *publicfields*, *all*, *standardtypes*, *fields*, *constructors*.
##   Setting it to *publicfieds* will check existence of objects declarations which
##   contains public fields. Setting it to *standardtypes* will check existence of
##   objects' declarations which contains fields with string or int type. Setting it
##   to *all* will perform all checks. Setting it to *fields* will perform checks for
##   public fields and standard types. Setting it to *constructors* will check
##   existence of constructors of objects. The rule follow Nim coding standards and
##   check if exist procedure or function which is named `newObjectName` or
##   `initObjectName`.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "objects"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for type `myObject`, the full declaration of it should
## be::
##
##     {.ruleOff: "objects".}
##     type myObject = object
##       field: string
##
## To enable the rule again, the pragma *ruleOn: "objects"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `myRecord` declaration, the full declaration
## should be::
##
##     {.ruleOn: "objects".}
##     type myRecord = object
##       field: string
##
## Examples
## --------
##
## 1. Check all objects' for public fieds, standard types and constructors::
##
##     check objects all
##
## 2. Made all object's types' fields private::
##
##     fix not objects publicfields

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "objects",
  ruleFoundMessage = "issues with object's types declarations",
  ruleNotFoundMessage = "issues with object's types declarations not found.",
  rulePositiveMessage = "type '{params[2]}', line: {params[0]} {params[1]}",
  ruleNegativeMessage = "type '{params[2]}', line: {params[0]} {params[1]}",
  ruleOptions = @[custom],
  ruleOptionValues = @["publicfields", "all", "standardtypes", "constructors",
      "fields"],
  ruleMinOptions = 1)

proc checkPublicFields(nodeChild: PNode; rule: RuleOptions;
    checkResult: var bool) {.raises: [], tags: [], contractual.} =
  ## Check if the object's type definition contains any public field
  ##
  ## * nodeChild   - the AST node to check
  ## * rule        - the rule's settings set by the user
  ## * checkResult - the result of the check
  ##
  ## Returns the modified parameter checkResult.
  body:
    block publicFields:
      let nodeToCheck: PNode = (if nodeChild.kind ==
          nkObjectTy: nodeChild else: nodeChild[0])
      for child in nodeToCheck:
        if child.kind == nkRecList:
          for field in child:
            if field.kind == nkRecCase:
              for elem in field:
                if elem.kind == nkIdentDefs:
                  for ident in elem:
                    if ident.kind == nkPostfix:
                      checkResult = true
                      break publicFields
                else:
                  for elemChild in elem:
                    if elemChild.kind == nkRecList:
                      for elemField in elemChild:
                        for ident in elemChild:
                          if ident.kind == nkPostfix:
                            checkResult = true
                            break publicFields
            else:
              for ident in field:
                if ident.kind == nkPostfix:
                  checkResult = true
                  break publicFields
    if rule.ruleType in {RuleTypes.count, search}:
      checkResult = not checkResult

proc checkStandardTypes(nodeChild: PNode; rule: RuleOptions;
    checkResult: var bool) {.raises: [], tags: [RootEffect], contractual.} =
  ## Check if the object's type definition contains fields with string or int
  ## type
  ##
  ## * nodeChild   - the AST node to check
  ## * rule        - the rule's settings set by the user
  ## * checkResult - the result of the check
  ##
  ## Returns the modified parameter checkResult.
  body:
    checkResult = false
    block standardTypes:
      let nodeToCheck: PNode = (if nodeChild.kind ==
          nkObjectTy: nodeChild else: nodeChild[0])
      for child in nodeToCheck:
        if child.kind == nkRecList:
          for field in child:
            if field.kind == nkRecCase:
              for elem in field:
                if elem.kind == nkIdentDefs:
                  try:
                    if ($elem[^2]).toLowerAscii in ["int", "string"]:
                      checkResult = true
                      break standardTypes
                  except Exception:
                    discard
                else:
                  for elemChild in elem:
                    if elemChild.kind == nkRecList:
                      for elemField in elemChild:
                        try:
                          if ($elemField[^2]).toLowerAscii in ["int", "string"]:
                            checkResult = true
                            break standardTypes
                        except Exception:
                          discard
            else:
              try:
                if ($field[^2]).toLowerAscii in ["int", "string"]:
                  checkResult = true
                  break standardTypes
              except Exception:
                discard
    if rule.ruleType in {RuleTypes.count, search}:
      checkResult = not checkResult

checkRule:
  initCheck:
    discard
  startCheck:
    discard
  checking:
    if node.kind == nkTypeSection:
      for objType in node:
        for nodeChild in objType:
          if nodeChild.kind == nkPragmaExpr:
            setRuleState(node = nodeChild[1], ruleName = ruleSettings.name,
                oldState = rule.enabled)
          if not rule.enabled:
            continue
          # Not an object declaration, skip it
          if nodeChild.kind notin {nkObjectTy, nkRefTy}:
            continue
          # No fields declared, skip it
          if nodeChild[2].kind == nkEmpty:
            continue
          var checkResult: bool = false
          # Check if the object's type definition contains any public field
          if rule.options[0].toLowerAscii in ["publicfields", "all", "fields"]:
            checkPublicFields(nodeChild = nodeChild, rule = rule,
                checkResult = checkResult)
            let oldAmount: ResultAmount = rule.amount
            try:
              let message: Message = (if rule.negation: "contains" else: "doesn't contain") & " public fields."
              setResult(checkResult = checkResult,
                  positiveMessage = positiveMessage,
                  negativeMessage = negativeMessage,
                  ruleData = "public fields",
                  node = objType, params = [$objType.info.line, message,
                      $objType[0]])
            except Exception:
              rule.amount = errorMessage(text = messagePrefix &
                  "can't check declaration of type " &
                  " line: " &
                  $nodeChild.info.line & ". Reason: ", e = getCurrentException())
            # To show the rule's explaination the rule.amount must be negative
            if rule.negation and oldAmount > rule.amount and rule.ruleType == check:
              rule.amount = -1_000
            if not checkResult and rule.options[0].toLowerAscii == "publicfields":
              break
          # Check if the object's type definition contains fields with string or int
          # type
          if rule.options[0].toLowerAscii in ["standardtypes", "all", "fields"]:
            checkStandardTypes(nodeChild = nodeChild, rule = rule,
                checkResult = checkResult)
            let oldAmount: ResultAmount = rule.amount
            try:
              let message: Message = (if rule.negation: "contains" else: "doesn't contain") & " field of int or string type."
              setResult(checkResult = checkResult,
                  positiveMessage = positiveMessage,
                  negativeMessage = negativeMessage,
                  ruleData = "standard types",
                  node = objType, params = [$objType.info.line, message,
                      $objType[0]])
            except Exception:
              rule.amount = errorMessage(text = messagePrefix &
                  "can't check declaration of type " &
                  " line: " &
                  $nodeChild.info.line & ". Reason: ", e = getCurrentException())
            # To show the rule's explaination the rule.amount must be negative
            if rule.negation and oldAmount > rule.amount and rule.ruleType == check:
              rule.amount = -1_000
            if not checkResult and rule.options[0].toLowerAscii == "standardtypes":
              break
          # Check if the module contains constructor for the object's type
          if rule.options[0].toLowerAscii in ["constructors", "all"]:
            checkResult = false
            type ObjectName = string
            var objectName: ObjectName = try:
                $objType[0]
              except Exception:
                ""
            if objectName.contains(sub = " "):
              objectName = objectName.split()[0]
            objectName.removeSuffix(c = '*')
            let constructorNames: array[4, string] = ["new" & objectName,
                "new" & objectName & "*", "init" & objectName, "init" &
                    objectName & "*"]
            var nodeToCheck: PNode = (if node in
                parentNode.sons: parentNode else: nil)
            if nodeToCheck == nil:
              for chNode in parentNode:
                if chNode.kind == nkStmtList and node in chNode.sons:
                  nodeToCheck = chNode
                  break
                for chNode2 in chNode:
                  if chNode2.kind == nkStmtList and node in chNode2.sons:
                    nodeToCheck = chNode2
                    break
            for child in nodeToCheck:
              if child.kind in {nkProcDef, nkFuncDef}:
                try:
                  if $child[0] in constructorNames:
                    checkResult = true
                except Exception:
                  rule.amount = errorMessage(text = messagePrefix &
                      "can't check for contructor of type " &
                      " line: " &
                      $nodeChild.info.line & ". Reason: ",
                      e = getCurrentException())
            if rule.ruleType in {RuleTypes.search, count}:
              checkResult = not checkResult
            let oldAmount: ResultAmount = rule.amount
            try:
              let message: Message = (if rule.negation: "has" else: "doesn't have") & " declared a constructor."
              setResult(checkResult = checkResult,
                  positiveMessage = positiveMessage,
                  negativeMessage = negativeMessage,
                  ruleData = "constructors",
                  node = objType, params = [$objType.info.line, message,
                      $objType[0]])
            except Exception:
              rule.amount = errorMessage(text = messagePrefix &
                  "can't check declaration of type " &
                  " line: " &
                  $nodeChild.info.line & ". Reason: ", e = getCurrentException())
            # To show the rule's explaination the rule.amount must be negative
            if rule.negation and oldAmount > rule.amount and rule.ruleType == check:
              rule.amount = -1_000
            if not checkResult:
              break
  endCheck:
    discard

fixRule:
  # Fix only public fields of the object
  if rule.options[0].toLowerAscii != "publicfields":
    return false
  # Made all fields of the object private
  if rule.negation:
    try:
      for child in astNode:
        if child.kind == nkRecList:
          for field in child:
            if field.kind == nkRecCase:
              for elem in field:
                if elem.kind == nkIdentDefs:
                  elem[0] = newIdentNode(ident = getIdent(ic = rule.identsCache,
                      identifier = ($elem[0])[0..^2]), info = elem[0].info)
                  result = true
                else:
                  for elemChild in elem:
                    if elemChild.kind == nkRecList:
                      for elemField in elemChild:
                        for ident in elemChild:
                          for index, identPart in ident:
                            if identPart.kind == nkPostfix:
                              ident[index] = newIdentNode(ident = getIdent(
                                  ic = rule.identsCache, identifier = ($ident[
                                  index])[0..^2]), info = ident.info)
                              result = true
            else:
              for i in 0..field.sons.len - 3:
                if field[i].kind == nkPostfix:
                  field[i] = newIdentNode(ident = getIdent(
                    ic = rule.identsCache,
                    identifier = ($field[i])[0..^2]), info = field.info)
                  result = true
    except KeyError, Exception:
      discard errorMessage(text = "Can't set the object's field public. Reason: " &
          getCurrentExceptionMsg())
      return false
  # Made all fields of the object public
  else:
    try:
      for child in astNode:
        if child.kind == nkRecList:
          for field in child:
            if field.kind == nkRecCase:
              for elem in field:
                if elem.kind == nkIdentDefs:
                  if elem[0].kind == nkIdent:
                    elem[0] = newIdentNode(ident = getIdent(
                        ic = rule.identsCache, identifier = $elem[0] & "*"),
                            info = elem[0].info)
                    result = true
                else:
                  for elemChild in elem:
                    if elemChild.kind == nkRecList:
                      for elemField in elemChild:
                        for ident in elemChild:
                          for i in 0..ident.sons.len - 3:
                            if ident[i].kind != nkPostfix:
                              ident[i] = newIdentNode(ident = getIdent(
                                  ic = rule.identsCache, identifier = $ident[
                                  i] & "*"), info = ident.info)
                              result = true
            else:
              for i in 0..field.sons.len - 3:
                if field[i].kind != nkPostfix:
                  field[i] = newIdentNode(ident = getIdent(
                    ic = rule.identsCache,
                    identifier = $field[i] & "*"), info = field.info)
                  result = true
    except KeyError, Exception:
      discard errorMessage(text = "Can't set the object's field public. Reason: " &
          getCurrentExceptionMsg())
      return false
