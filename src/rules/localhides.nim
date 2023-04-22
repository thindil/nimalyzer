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

## The rule check if the local declarations in the module don't hide (have the
## same name) as a global declarations declared in the module.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? localHides
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check rule will
##   raise an error if find a local declaration which has the same name as
##   one of global declarations, search rule will list any local declarations
##   with the same name as previously declared global and raise an error if
##   nothing found. Count rule will simply list the amount of local
##   declarations which have the same name as global ones.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about local declarations which don't have name as
##   previously declared global ones. Probably useable only for count type of
##   rule.
## * localHides is the name of the rule. It is case-insensitive, thus it can be
##   set as *localhides*, *localHides* or *lOcAlHiDeS*.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "localHides"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for procedure `proc main()`, the full declaration of it should
## be::
##
##     proc main () {.ruleOff: "localHides".}
##
## To enable the rule again, the pragma *ruleOn: "localHides"* should be added in
## the element which should be checked or in code before it. For example, if
## the rule should be re-enabled for `const a = 1`, the full declaration should
## be::
##
##     const a {.ruleOn: "localHides".} = 1
##
## Examples
## --------
##
## 1. Check if any local declaration hides the global ones::
##
##     check localHides
##
## 2. Search for all local declarations which not hide the global ones::
##
##     search not localHides

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "localhides",
  ruleFoundMessage = "local declarations which hide global declarations",
  ruleNotFoundMessage = "Local declarations which hide global declarations not found.")

checkRule:
  initCheck:
    discard
  startCheck:
    discard
  checking:
    discard
  endCheck:
    discard
