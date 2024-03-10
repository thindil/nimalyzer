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

## The rule to check if all public declarations (variables, procedures, etc)
## have documentation comments. It doesn't check public fields of types
## declarations for the documentation.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? hasDoc [entityType] [templateFile]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a public declaration which doesn't have documentation.
##   Search type will list all public declarations which have documentation and
##   raise error if nothing was found. Count type will simply list the amount
##   of public declarations which have documentation. Fix type with negation
##   will remove all documentation from the selected type of the code entities.
##   Without negation, it will add a template of documentation from the selected
##   text file into the configured type of code entities.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about public declaration which have documentation.
##   Probably useable only with search and count type of rule.
## * hasDoc is the name of the rule. It is case-insensitive, thus it can be
##   set as *hasdoc*, *hasDoc* or *hAsDoC*.
## * entityType is the type of entity which will be looking for. Proper values
##   are: `all`: check everything what can have documentation but without fields
##   of objects' declarations, `callables`: check all declarations of
##   subprograms (procedures, functions, macros, etc.), `types`: check declarations
##   of types, `typesFields`: check declarations of objects' fields, `modules`:
##   check only module for documentation.
## * templateFile is parameter required only by *fix* type of hasDoc rule.
##   Other types of the rule can skip setting it. It should contain the template
##   of documentation which will be inserted into the checked code. The
##   documentation should be in reStructuredText format without leading sign
##   for Nim documentation. It will be inserted in all desired types of entities.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "hasDoc"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should be
## disabled for procedure `proc main()`, the full declaration of it should be::
##
##     proc main () {.ruleOff: "hasDoc".}
##
## To enable the rule again, the pragma *ruleOn: "hasDoc"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `const a = 1`, the full declaration should
## be::
##
##     const a {.ruleOn: "hasDoc".} = 1
##
## Examples
## --------
##
## 1. Check if all public declarations in module have documentation::
##
##     check hasDoc all
##
## 2. Search for all modules which don't have documentation::
##
##     search not hasDoc modules

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "hasdoc",
  ruleFoundMessage = "declared public items with{negation} documentation",
  ruleNotFoundMessage = "The documentation not found.",
  rulePositiveMessage = "Declaration of {params[0]} at {params[1]} has documentation.",
  ruleNegativeMessage = "Declaration of {params[0]} at {params[1]} doesn't have documentation.",
  ruleOptions = @[custom, str],
  ruleOptionValues = @["all", "callables", "types", "typesfields", "modules"],
  ruleMinOptions = 1)

var docTemplate: string = ""

{.hint[XCannotRaiseY]: off.}
checkRule:
  initCheck:
    if rule.enabled:
      if rule.ruleType == fix and not rule.negation:
        if rule.options.len < 2:
          rule.amount = errorMessage(text = "Can't set the documentation's template for hasDoc rule. No file with the template specified in the rule's options.")
        else:
          try:
            docTemplate = readFile(filename = rule.options[1])
            docTemplate.stripLineEnd
          except IOError:
            rule.amount = errorMessage(text = "Can't read the documentation template for hasDoc rule. Reason: ",
              e = getCurrentException())
    if rule.enabled and rule.options[0].toLowerAscii in ["all", "modules"]:
      setResult(checkResult = astNode.hasSonWith(kind = nkCommentStmt),
          positiveMessage = "Module has documentation.",
          negativeMessage = "Module doesn't have documentation.",
          node = astNode)
  startCheck:
    let
      nodesToCheck: set[TNodeKind] = case rule.options[0].toLowerAscii
        of "all":
          {nkIdentDefs, nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef,
              nkTemplateDef, nkIteratorDef, nkConstDef, nkTypeDef, nkEnumTy,
              nkConstSection, nkConstTy, nkVarSection, nkTypeSection, nkObjectTy,
              nkLetSection}
        of "callables":
          {nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef, nkIteratorDef}
        of "types":
          {nkTypeSection, nkTypeDef, nkEnumTy, nkObjectTy, nkConstTy}
        of "typesfields":
          {nkIdentDefs}
        else:
          {}
      negation: string = (if rule.negation: "out" else: "")
  checking:
    # Check only elements which can have documentation
    if node.kind in nodesToCheck:
      # Special check for sections
      if node.kind in {nkConstSection, nkVarSection, nkTypeSection, nkTypeDef, nkLetSection}:
        ruleCheck(astNode = node, parentNode = parentNode, rule = rule)
      # Don't check documentation for fields of objects, unless the user set
      # the option for it
      if (node.kind == nkIdentDefs and parentNode.kind in {nkTypeDef,
          nkObjectTy, nkRecCase}) and rule.options[0].toLowerAscii != "typesfields":
        continue
      # Don't check deeper types declarations or we get many error messages
      # about the same
      if node.kind in {nkEnumTy, nkObjectTy}:
        continue
      else:
        try:
          if '=' in $node[namePos]:
            continue
        except:
          discard
        # Set the name of the declared entity which is checked for documentation
        var declName: string = try:
              ($node[namePos]).split[0]
            except KeyError, Exception:
              ""
        if declName.len == 0:
          declName = try:
              $astNode[namePos]
            except KeyError, Exception:
              ""
        if declName.len == 0:
          rule.amount = errorMessage(
              text = "Can't get the name of the declared entity.")
          return
        if rule.enabled and (declName.endsWith(suffix = "*") or
            node.kind in callableDefs):
          try:
            var hasDoc: bool = if node.kind in {nkEnumTy, nkIdentDefs, nkConstDef}:
                node.comment.len > 0
              elif node.kind == nkObjectTy:
                node[2].comment.len > 0
              elif node.kind in callableDefs and node[bodyPos].len == 0:
                node.comment.len > 0
              elif node.kind == nkTypeDef:
                case node[2].kind
                of nkEnumTy:
                  node[2].comment.len > 0
                of nkObjectTy:
                  node[2][2].comment.len > 0
                of nkRefTy:
                  node[2][0][2].comment.len > 0
                else:
                  node.comment.len > 0
              else:
                node[^1].len > 0 and node[^1][0].kind == nkCommentStmt
            if node.kind == nkTemplateDef and not hasDoc:
              hasDoc = node.comment.len > 0
            setResult(checkResult = hasDoc, positiveMessage = positiveMessage,
                negativeMessage = negativeMessage, node = node, params = [
                declName, $node.info.line])
          except KeyError as e:
            rule.amount = errorMessage(
                text = "Can't check the declared entity '" & declName & "'.", e = e)
            return
  endCheck:
    discard
{.hint[XCannotRaiseY]: on.}

fixRule:
  # Remove the documentation
  if rule.negation:
    if astNode.kind == nkObjectTy:
      astNode[2].comment = ""
    elif astNode.kind notin {nkEnumTy, nkIdentDefs, nkConstDef}:
      for index, node in astNode:
        if node.kind == nkCommentStmt:
          astNode.delSon(idx = index)
          return true
        if node.kind == nkStmtList:
          for index, subNode in node:
            if subNode.kind == nkCommentStmt:
              node.delSon(idx = index)
              return true
    else:
      astNode.comment = ""
    return true
  # Add the selected documentation template
  if docTemplate.len == 0:
    discard errorMessage(text = "Can't add the documentation's template the declarations. No template set.")
    return false
  if astNode.kind == nkObjectTy:
    astNode[2].comment = docTemplate
  elif astNode.kind notin {nkEnumTy, nkIdentDefs, nkConstDef}:
    let docNode: PNode = newNode(kind = nkCommentStmt)
    docNode.comment = docTemplate
    astNode.sons = docNode & astNode.sons
  else:
    astNode.comment = docTemplate
  return true
