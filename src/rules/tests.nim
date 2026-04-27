# Copyright © 2026 Bartek thindil Jasicki
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

## The rule to check if all routines have a test's suite. It is a very
## simple rule, it only check if there is a call for the selected routine in
## a file which has the same name as the checked file.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? tests [testsType] ?path?
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search*, *count* and *fix*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise an
##   error if the selec routine has a test's suite. Search type will list
##   all routines which have test's suites and raise error if nothing was
##   found. Count type will simply list the amount of routines which have
##   own test's suites. Fix type will execute the default shell command set by
##   the program's setting **fixCommand**.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about routines which not have a test's suite.
## * tests is the name of the rule. It is case-insensitive, thus it can be
##   set as *tests*, *tests* or *tEsT*.
## * testsType is the type of tests' suite which the rule will looking for. Possible
##   values are: calls - the rule will looking for calls of routines in the test
##   file, unittest2 - the rule will looking for calls inside structure typical
##   for status-im/nim-unittest2 project.
## * path - optional the absolute or relative path to directory where tests are
##   located. It must be in Unix form, which will be converted if needed by the
##   program. Files with tests must have the same names as the source code files.
##   The path is relative to the directory from which the program is executed.
##   If not set, the rule will be looking into the same file.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "tests"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for procedure `proc main()`, the full declaration of it should
## be::
##
##     proc main() {.ruleOff: "tests".}
##
## To enable the rule again, the pragma *ruleOn: "tests"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for procedure `proc alpha()`, the full
## declaration should be::
##
##     proc alpha() {.ruleOn: "tests".}
##
## Examples
## --------
##
## 1. Check if all routines have tests with status-im/nim-unittest2 style which are in tests directory::
##
##     check not tests unittest2 tests
##
## 2. Search for routine with test's suite as normal calls in the same files::
##
##     search tests calls

# Standard library imports
import std/hashes
# External modules imports
import compiler/[idents, llstream, options, parser, pathutils]
# Import default rules' modules
import ../rules

ruleConfig(ruleName = "tests",
  ruleFoundMessage = "routines with test's suite found",
  ruleNotFoundMessage = "routines with test's suite not found.",
  rulePositiveMessage = "routine '{params[2]}', line: {params[0]} {params[1]}",
  ruleNegativeMessage = "routine '{params[2]}', line: {params[0]} {params[1]}",
  ruleOptions = @[custom, str],
  ruleOptionValues = @["calls", "unittest2"],
  ruleMinOptions = 1)

type
  ProcName = string

var
  checked: seq[Hash] = @[]
  nodesToCheck: PNode = nil

checkRule:
  initCheck:
    if rule.enabled:
      # Read the test file if needed
      if rule.options.len > 1:
        let
          source: FilePath = rule.options[1] & DirSep &
              rule.fileName.extractFilename
          fileName: AbsoluteFile = try:
              toAbsolute(file = source, base = toAbsoluteDir(
                  path = getCurrentDir()))
            except OSError:
              rule.amount = errorMessage(
                  text = "Can't set the file with tests. Reason: ",
                  e = getCurrentException())
              return
          nimCache: IdentCache = newIdentCache()
          nimConfig: ConfigRef = newConfigRef()
        nimConfig.options.excl(y = optHints)
        if not fileExists(x = fileName):
          rule.amount = errorMessage(text = "Can't open the test file '" &
              $fileName & "'")
          return
        var codeParser: Parser = Parser()
        try:
          openParser(p = codeParser, filename = fileName,
              inputStream = llStreamOpen(filename = fileName,
              mode = fmRead), cache = nimCache, config = nimConfig)
        except IOError, ValueError, KeyError, Exception:
          rule.amount = errorMessage(text = "Can't open test file '" & source &
              "' to parse. Reason: ", e = getCurrentException())
        try:
          nodesToCheck = codeParser.parseAll
        except IOError, OSError, Exception:
          rule.amount = errorMessage(
              text = "Can't parse the file with tests. Reason: ",
              e = getCurrentException())
          return
        codeParser.closeParser
      else:
        nodesToCheck = parentNode
      try:
        echo "NODES:"
        echo nodesToCheck
        echo "ENDNODES"
      except:
        discard
    checked = @[]
  startCheck:
    discard
  checking:
    if node.kind in routineDefs:
      let
        procName: ProcName = try:
            $node[namePos]
          except Exception:
            rule.amount = errorMessage(
                text = "Can't get the name of the procedure.")
            return
        routineHash: Hash = try:
            hash(x = procName & $node[paramsPos])
          except Exception:
            rule.amount = errorMessage(
                text = "Can't set the hash of the procedure.")
            return
      try:
        if ($node[bodyPos]).len == 0:
          checked.add(y = routineHash)
        elif routineHash in checked:
          continue
      except Exception:
        rule.amount = errorMessage(text = "Can't check if procedure was checked previously.")
        return
      for child in nodesToCheck:
        if child.kind in {nkCall, nkDotCall}:
          echo "CHILD"
          try:
            echo child
          except:
            discard
          echo "ENDCHILD"
  endCheck:
    discard

fixRule:
  discard
