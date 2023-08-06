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

## The rule to check if the selected file contains a comment with the selected
## pattern or a legal header. In the second option, it looks for word *copyright*
## in the first 5 lines of the file. The rule works differently than other rules,
## because it doesn't use AST representation of the checked code but operates
## directly on the file which contains the code.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? comments [checkType] [patternOrFileName]
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   an error if there is a comment with the selected pattern (if pattern is
##   checked) or there is no legal header in the code. Search type will list
##   all comments which violates any of checks or raise an error if nothing
##   found. Count type will simply list the amount of the comments which
##   violates the checks. Fix remove the comment with the selected pattern
##   from the code or add the selected legal header from file. In any other
##   setting, the fix type will execute the default shell command set by the
##   program's setting **fixCommand**.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about the comments which not violate the check.
## * comments is the name of the rule. It is case-insensitive, thus it can be
##   set as *comments*, *comments* or *--cOmMeNtS--*.
## * checkType is the type of check to perform on the code's comments. Proper
##   values are: *pattern* and *legal*. Pattern will check all the comments in
##   the code against regular expression. Legal will check if the source code
##   file contains legal information header.
## * patternOrFileName parameter depends on the type of check. For *pattern*
##   type it is a regular expression against which the comments will be checked.
##   For *legal* type, it is the path to the file which contains the legal
##   header, which will be inserted into code. Thus, in that situation, the
##   parameter is required only for *fix* type of the rule. The file containing
##   the legal header should contain only text of the header without comment marks.
##   They will be added automatically by the rule.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "comments"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for procedure `proc main()`, the full declaration of it should
## be::
##
##     proc main () {.ruleOff: "comments".}
##
## To enable the rule again, the pragma *ruleOn: "comments"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `const a = 1`, the full declaration should
## be::
##
##     const a {.ruleOn: "comments".} = 1
##
## Examples
## --------
##
## 1. Check if there is a comment which starts with FIXME word::
##
##    check comments pattern ^FIXME
##
## 2. Add a legal header from file legal.txt::
##
##    fix comments legal legal.txt

# Standard library imports
import std/re
# Import default rules' modules
import ../rules

ruleConfig(ruleName = "comments",
  ruleFoundMessage = "comments which {negation}match the pattern found",
  ruleNotFoundMessage = "comments which {negation}match the pattern not found.",
  rulePositiveMessage = "Comment at line: {params[0]} match the pattern '{params[1]}'.",
  ruleNegativeMessage = "Comment at line: {params[0]} doesn't match the pattern '{params[1]}'.",
  ruleOptions = @[custom, str],
  ruleOptionValues = @["pattern", "legal"],
  ruleMinOptions = 1)

checkRule:
  initCheck:
    if rule.options[0] == "pattern" and rule.options.len < 2:
      rule.amount = errorMessage(text = "Can't check the comments pattern. No regular expression pattern specified in the rule's options.")
      return
    if rule.options[0] == "legal" and not rule.negation and rule.ruleType ==
        fix and rule.options.len < 2:
      rule.amount = errorMessage(text = "Can't fix the comment. No file with the legal header specified in the rule's options.")
      return
  startCheck:
    let
      negation: string = (if rule.negation: "doesn't " else: "")
      convention: Regex = (if rule.options.len > 1: rule.options[
          1].re else: "^.".re)
  checking:
    try:
      var lineNumber: Natural = 0
      for line in lines(fileName = rule.fileName):
        lineNumber.inc
        var cleanLine: string = line.strip()
        if cleanLine.startsWith(prefix = '#') and cleanLine.len > 2:
          cleanLine = cleanLine[cleanLine.find(sub = ' ') + 1 .. ^1]
          case rule.options[0]
          # Check comment against the selected pattern
          of "pattern":
            setResult(checkResult = match(s = cleanLine, pattern = convention),
                positiveMessage = positiveMessage,
                negativeMessage = negativeMessage, node = node,
                ruleData = "pattern", params = [$lineNumber, rule.options[1]])
          # Check the first 5 lines of file, do the comment contains word "copyright"
          of "legal":
            if lineNumber == 5:
              break
            if "copyright" in cleanLine.toLowerAscii:
              setResult(checkResult = true, positiveMessage = "File '" &
                  rule.fileName & "' contains a legal header.",
                  negativeMessage = "File '" & rule.fileName &
                  "' doesn't contain a legal header.", node = node,
                  ruleData = "legal", params = [$lineNumber])
              break
          else:
            discard
      if rule.options[0] == "legal" and lineNumber > 4:
        setResult(checkResult = false, positiveMessage = "File '" &
            rule.fileName & "' contains a legal header.",
            negativeMessage = "File '" & rule.fileName &
            "' doesn't contain a legal header.", node = node, ruleData = "legal",
            params = [$lineNumber])
    except IOError:
      rule.amount = errorMessage(text = messagePrefix & "can't check file '" &
          rule.fileName & ". Reason: ", e = getCurrentException())
    break
  endCheck:
    discard

fixRule:

  proc revertChanges(fileName: string, e: ref Exception): bool {.raises: [],
      tags: [WriteIOEffect, ReadIOEffect, RootEffect], contractual.} =
    ## Revert changes to the checked file from the old version and print
    ## information about the issue
    ##
    ## * fileName - the name of the old file which will be restored
    ## * e        - the exception which occured
    ##
    ## This procedure always returns false
    require:
      fileName.len > 0
      e != nil
    body:
      discard errorMessage(text = "Can't fix file '" &
          rule.fileName & ". Reason: ", e = e)
      try:
        removeFile(file = rule.fileName)
      except OSError:
        discard
      try:
        moveFile(source = fileName, dest = rule.fileName)
      except IOError, OSError, Exception:
        discard
      return false

  let newFileName: string = rule.fileName & ".bak"
  case data
  # If comment has the regex pattern in itself, remove it
  of "pattern":
    if not rule.negation:
      return false
    try:
      moveFile(source = rule.fileName, dest = newFileName)
      let
        convention: Regex = rule.options[1].re
        newFile: File = open(filename = rule.fileName, mode = fmWrite)
      for line in newFileName.lines:
        var cleanLine: string = line.strip()
        if cleanLine.startsWith(prefix = '#') and cleanLine.len > 2:
          cleanLine = cleanLine[cleanLine.find(sub = ' ') + 1 .. ^1]
          if match(s = cleanLine, pattern = convention):
            continue
        newFile.writeLine(x = line)
      newFile.close
    except RegexError, OSError, IOError, Exception:
      return revertChanges(fileName = newFileName, e = getCurrentException())
  # If there is no legal header, add one from file
  of "legal":
    if rule.negation:
      return false
    try:
      moveFile(source = rule.fileName, dest = newFileName)
      let newFile: File = open(filename = rule.fileName, mode = fmWrite)
      for line in rule.options[1].lines:
        newFile.writeLine(x = "# " & line)
      newFile.writeLine(x = "")
      for line in newFileName.lines:
        newFile.writeLine(x = line)
    except RegexError, OSError, IOError, Exception:
      return revertChanges(fileName = newFileName, e = getCurrentException())
  else:
    return false
  try:
    removeFile(file = newFileName)
  except OSError:
    discard
  return false
