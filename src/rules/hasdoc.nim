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
## have documentation comments
## The syntax in a configuration file is::
##
##   [ruleType] ?not? hasDoc
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a public declarations which doesn't have documentation.
##   Search type will list all public declarations which have documentation and
##   raise error if nothing was found. Count type will simply list the amount
##   of public declarations which have documentation.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about public declaration which have documentation.
##   Probably useable only with search and count type of rule.
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

# Standard library imports
import std/[logging, strutils]
# External modules imports
import compiler/[ast, renderer]
import contracts
# Internal modules imports
import ../rules

const ruleName* = "hasdoc"

proc ruleCheck*(astTree: PNode; options: RuleOptions): int {.contractual,
    raises: [], tags: [RootEffect].} =
  require:
    astTree != nil
    options.fileName.len > 0
  body:
    result = options.amount
    let messagePrefix = if getLogFilter() < lvlNotice:
        ""
      else:
        options.fileName & ": "

    proc setResult(entityName, line: string; hasDoc: bool;
        oldResult: var int) {.raises: [], tags: [RootEffect], contractual.} =
      require:
        entityName.len > 0
      body:
        if not hasDoc:
          if options.negation and options.ruleType == check:
            return
          if options.ruleType == check:
            message(text = messagePrefix & entityName & (if line.len >
                0: " line: " & line else: "") & " doesn't have documentation.",
                returnValue = oldResult)
          else:
            if options.negation:
              message(text = messagePrefix & entityName & (if line.len >
                  0: " line: " & line else: "") &
                  " doesn't have documentation.", returnValue = oldResult,
                  level = lvlNotice, decrease = false)
        else:
          if options.negation:
            if options.ruleType == check:
              message(text = messagePrefix & entityName & (if line.len >
                  0: " line: " & line else: "") & " has documentation.",
                  returnValue = oldResult)
            else:
              oldResult.dec
          if options.ruleType == search:
            message(text = messagePrefix & entityName & (if line.len >
                0: " line: " & line else: "") & " has documentation.",
                returnValue = oldResult, level = lvlNotice, decrease = false)
          else:
            oldResult.inc

    if options.parent:
      setResult(entityName = "Module", line = "",
          hasDoc = astTree.hasSubnodeWith(kind = nkCommentStmt),
          oldResult = result)
    for node in astTree.items:
      for child in node.items:
        result = ruleCheck(astTree = child, options = RuleOptions(
            options: options.options, parent: false,
            fileName: options.fileName, negation: options.negation,
            ruleType: options.ruleType, amount: result))
      if node.kind notin {nkIdentDefs, nkProcDef, nkMethodDef, nkConverterDef,
          nkMacroDef, nkTemplateDef, nkIteratorDef, nkConstDef, nkTypeDef, nkEnumTy}:
        continue
      var declName = try:
            $node[0]
          except KeyError, Exception:
            ""
      if declName.len == 0:
        declName = try:
            $astTree[0]
          except KeyError, Exception:
            ""
      if declName.len == 0:
        message(text = "Can't get the name of the declared entity.",
            level = lvlFatal, returnValue = result)
        result.inc
        return
      if not declName.endsWith(suffix = "*") and node.kind notin callableDefs:
        continue
      try:
        let hasDoc: bool = if node.kind in {nkEnumTy, nkIdentDefs}:
            if node.comment.len > 0: true else: false
          else:
            node.hasSubnodeWith(kind = nkCommentStmt)
        setResult(entityName = "Declaration of " & declName,
            line = $node.info.line, hasDoc = hasDoc, oldResult = result)
      except KeyError:
        message(text = "Can't check the declared entity '" & declName & "'.",
            level = lvlFatal, returnValue = result)
        result.inc
        return
    if options.parent:
      if result == 0 and options.ruleType == search:
        message(text = "The documentation not found.", returnValue = result)
        return 0
      if options.ruleType == RuleTypes.count:
        message(text = (if getLogFilter() <
            lvlNotice: "D" else: options.fileName & ": d") &
                "eclared public items with documentation found: " & $result,
                returnValue = result, level = lvlNotice)
        return 1
