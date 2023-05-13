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

## The rule to check if all public declarations (variables, procedures, etc)
## have documentation comments. It doesn't check public fields of types
## declarations for the documentation.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? hasDoc
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a public declaration which doesn't have documentation.
##   Search type will list all public declarations which have documentation and
##   raise error if nothing was found. Count type will simply list the amount
##   of public declarations which have documentation.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about public declaration which have documentation.
##   Probably useable only with search and count type of rule.
## * hasDoc is the name of the rule. It is case-insensitive, thus it can be
##   set as *hasdoc*, *hasDoc* or *hAsDoC*.
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
##     check hasDoc
##
## 2. Search for all public declarations which don't have documentation::
##
##     search not hasDoc

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "hasdoc",
  ruleFoundMessage = "declared public items with documentation",
  ruleNotFoundMessage = "The documentation not found.",
  rulePositiveMessage = "Declaration of {params[0]} at {params[1]} has documentation.",
  ruleNegativeMessage = "Declaration of {params[0]} at {params[1]} doesn't have documentation.")

checkRule:
  initCheck:
    if rule.enabled:
      setResult(checkResult = astNode.hasSonWith(kind = nkCommentStmt),
          positiveMessage = "Module has documentation.",
          negativeMessage = "Module doesn't have documentation.")
  startCheck:
    discard
  checking:
    # Check only elements which can have documentation
    if node.kind in {nkIdentDefs, nkProcDef, nkMethodDef, nkConverterDef,
        nkMacroDef, nkTemplateDef, nkIteratorDef, nkConstDef, nkTypeDef,
        nkEnumTy, nkConstSection, nkConstTy, nkVarSection}:
      # Special check for constant and variables declaration section
      if node.kind in {nkConstSection, nkVarSection}:
        ruleCheck(astNode = node, parentNode = parentNode, rule = rule)
      # Don't check documentation for fields of objects
      if node.kind == nkIdentDefs and parentNode.kind == nkTypeDef:
        continue
      else:
        # Set the name of the declared entity which is checked for documentation
        var declName: string = try:
              $node[0]
            except KeyError, Exception:
              ""
        if declName.len == 0:
          declName = try:
              $astNode[0]
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
              else:
                node[^1].len > 0 and node[^1][0].kind == nkCommentStmt
            if node.kind == nkTemplateDef and not hasDoc:
              hasDoc = node.comment.len > 0
            setResult(checkResult = hasDoc, positiveMessage = positiveMessage,
                negativeMessage = negativeMessage, params = [declName,
                $node.info.line])
          except KeyError as e:
            rule.amount = errorMessage(
                text = "Can't check the declared entity '" & declName & "'.", e = e)
            return
  endCheck:
    discard

fixRule:
  discard
