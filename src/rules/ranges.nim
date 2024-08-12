# Copyright © 2024 Bartek thindil Jasicki
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

## The rule to check do ranges' declarations in the code follow some design
## patterns.
## Checked things:
##
## * Do ranges' declarations have space before and after `..` sign.
##
## The syntax in a configuration file is::
##
##   [ruleType] ?not? ranges [checkType]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a declaration which violates any of the checks. Search
##   type will list all declarations which violates any of checks or raise an
##   error if nothing found. Count type will simply list the amount of the
##   declarations which violates the checks. Fix type will try to upgrade the
##   declaration to meet the rule settings. For example, it will add spaces before
##   and after `..` sign or remove them if negation was used.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about declarations which not violate the checks. For
##   example, it will raise an error when check type find a declaration with space
##   before and after `..` sign.
## * ranges is the name of the rule. It is case-insensitive, thus it can be
##   set as *ranges*, *ranges* or *rAnGeS*.
## * checkType is the type of checks to perform on the declarations. Proper
##   value is: *spaces*. It will check if all declarations do they have spaces
##   before and after `..` sign.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "ranges"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for procedure `proc main()`, the full declaration of it should
## be::
##
##     proc main() {.ruleOff: "ranges".}
##
## To enable the rule again, the pragma *ruleOn: "ranges"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for procedure `proc main()`, the full declaration should
## be::
##
##     proc main() {.ruleOn: "ranges".}
##
## Examples
## --------
##
## 1. Check if all ranges' declarations in the code have spaces before and after
## `..` sign, the opposite to the Nim coding standard ::
##
##     check ranges spaces
##
## 2. Replace all range's declarations in the code with the Nim coding standard::
##
##     fix not ranges spaces

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "ranges",
  ruleFoundMessage = "range declaration which can{negation} be upgraded",
  ruleNotFoundMessage = "range declarations which can{negation} be upgraded not found.",
  rulePositiveMessage = "range declaration, line: {params[0]} {params[1]}.",
  ruleNegativeMessage = "range declaration, line: {params[0]} {params[1]}",
  ruleOptions = @[custom],
  ruleOptionValues = @["spaces"],
  ruleMinOptions = 1)

type FileLine = string

var
  fileContent: seq[string] = @[]
  needSave: bool = false

checkRule:
  initCheck:
    fileContent = try:
          rule.fileName.readFile.splitLines
      except IOError:
        rule.amount = errorMessage(text = messagePrefix & "can't read file '" &
            rule.fileName & ". Reason: ", e = getCurrentException())
        return
  startCheck:
    let negation: Message = (if rule.negation: "" else: "'t")
    var hasMessage: Message = (if rule.negation: "has" else: "doesn't have")
    if rule.ruleType != check:
      hasMessage = (if rule.negation: "doesn't have" else: "has")
  checking:
    try:
      if node.kind == nkIdent and $node == "..":
        let
          rangeLine: FileLine = fileContent[node.info.line.Natural - 1]
          checkResult: bool = rangeLine[rangeLine.find(sub = "..") - 1] == ' '
        if rule.ruleType == fix and not needSave and (not checkResult or (
            checkResult and rule.negation)):
          needSave = true
        setResult(checkResult = checkResult, positiveMessage = positiveMessage,
            negativeMessage = negativeMessage, ruleData = $node.info.line,
            node = node, params = [$node.info.line, hasMessage &
            " spaces between start and end of the range"])
    except IOError, Exception:
      rule.amount = errorMessage(text = messagePrefix & "can't check file '" &
          rule.fileName & ". Reason: ", e = getCurrentException())
  endCheck:
    if rule.ruleType == fix and needSave:
      let newFileName: FilePath = rule.fileName & ".bak"
      try:
        moveFile(source = rule.fileName, dest = newFileName)
        let newFile: File = open(filename = rule.fileName, mode = fmWrite)
        for index, line in fileContent:
          newFile.writeLine(x = line)
        newFile.close
      except OSError, IOError, Exception:
        discard errorMessage(text = "Can't save file '" &
            rule.fileName & ". Reason: ", e = getCurrentException())
        try:
          removeFile(file = rule.fileName)
        except OSError:
          discard
        try:
          moveFile(source = newFileName, dest = rule.fileName)
        except IOError, OSError, Exception:
          discard

fixRule:
  let lineNumber: Natural = try:
      data.parseInt
    except ValueError:
      discard errorMessage(text = "Can't fix file '" &
          rule.fileName & ". Reason: ", e = getCurrentException())
      return false
  if rule.negation:
    fileContent[lineNumber] = fileContent[lineNumber].replace(sub = " ..", by = "..")
  else:
    fileContent[lineNumber] = fileContent[lineNumber].replace(sub = "..", by = " .. ")
  echo fileContent
