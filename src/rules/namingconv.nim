# Copyright © 2023 Bartek thindil Jasicki
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

## The rule check if the selected type of entries follow the selected naming
## convention. It can check variables, procedures and enumerations' values.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? namingConv [entityType] [nameExpression]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a selected entity type which doesn't follow the
##   selected naming convention. Search type will list all entities of the
##   selected type which follows the selected naming convention. Count type
##   will simply list the amount of the selected type of entities, which follows
##   the naming convention. Fix type will execute the default shell command set
##   by the program's setting **fixCommand**.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about the selected type of entities, which doesn't
##   follow the selected naming convention for search and count types of rules
##   and raise error if the entity follows the naming convention for check type
##   of the rule.
## * namingConv is the name of the rule. It is case-insensitive, thus it can be
##   set as *namingconv*, *namingConv* or *nAmInGcOnV*.
## * entityType is the type of code's entities to check. Possible values are:
##   variables - check the declarations of variables, enumerations - check the
##   names of enumerations values and procedures - check the names of the
##   declarations of procedures.
## * nameExpression - the regular expression which the names of the selected
##   entities should follow. Any expression supported by PCRE is allowed.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "namingConv"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for procedure `proc main()`, the full declaration of it should
## be::
##
##     proc main () {.ruleOff: "namingConv".}
##
## To enable the rule again, the pragma *ruleOn: "namingConv"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `const a = 1`, the full declaration should
## be::
##
##     const a {.ruleOn: "namingConv".} = 1
##
## Examples
## --------
##
## 1. Check if names of variables follow standard Nim convention::
##
##     check namingConv variables [a-z][A-Z0-9_]*
##
## 2. Find procedures which names ends with *proc*::
##
##     search namingConv procedures proc$
##
## 3. Count enumerations which values are not start with *enum*::
##
##     count not namingConv enumerations ^enum

# Standard library imports
import std/re
# Import default rules' modules
import ../rules

ruleConfig(ruleName = "namingconv",
  ruleFoundMessage = "declarations which {negation}follow naming convention",
  ruleNotFoundMessage = "declarations which {negation}follow naming convention not found.",
  rulePositiveMessage = "name of '{params[0]}' line: {params[1]} follow naming convention.",
  ruleNegativeMessage = "name of '{params[0]}' line: {params[1]} doesn't follow naming convention.",
  ruleOptions = @[custom, str],
  ruleOptionValues = @["variables", "enumerations", "procedures"],
  ruleMinOptions = 2)

checkRule:
  initCheck:
    discard
  startCheck:
    let
      convention: Regex = rule.options[1].re
      nodesToCheck: set[TNodeKind] = case rule.options[0]
        of "variables":
          {nkVarSection, nkLetSection, nkConstSection}
        of "procedures":
          {nkProcDef, nkFuncDef, nkMethodDef}
        of "enumerations":
          {nkEnumTy}
        else:
          {}
  checking:
    try:
      # Sometimes the compiler detects declarations as children of the node
      if node.kind in nodesToCheck:
        # Check each variable declaration if meet the rule requirements
        for declaration in node.items:
          if declaration.kind == nkEmpty:
            continue
          let nameToCheck: string = (if declaration.kind in {nkCharLit ..
              nkTripleStrLit, nkSym, nkIdent}: $declaration else: $declaration[0])
          setResult(checkResult = match(s = nameToCheck, pattern = convention),
              positiveMessage = positiveMessage,
              negativeMessage = negativeMessage, node = declaration, params = [
              nameToCheck, $declaration.info.line])
          if rule.options[0] == "procedures":
            break
      # And sometimes the compiler detects declarations as the node
      elif node.kind == nkIdentDefs and astNode.kind in nodesToCheck:
        setResult(checkResult = match(s = $node[0], pattern = convention),
            positiveMessage = positiveMessage, node = node,
            negativeMessage = negativeMessage, params = [$node[0],
            $node.info.line])
    except KeyError, Exception:
      rule.amount = errorMessage(text = messagePrefix &
        "can't check name of " & rule.options[0][0 .. ^2] &
        " line: " & $node.info.line & ". Reason: ",
        e = getCurrentException())
  endCheck:
    let negation: string = (if rule.negation: "not " else: "")

fixRule:
  discard
