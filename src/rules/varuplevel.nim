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

## The rule checks if declarations of local variables can be changed from var
## to let or const and from let to const.
## The syntax in a configuration file is::
##
##   [ruleType] ?not? varUplevel
##
## * ruleType is the type of rule which will be executed. Proper values are:
##   *check*, *search* and *count*. For more information about the types of
##   rules, please refer to the program's documentation. Check type will raise
##   error when the declaration of the variable can be changed into let or
##   const. Search type will list all declrations which can be updated and
##   count type will show the amount of variables' declarations which can be
##   updated.
## * optional word *not* means negation for the rule. Adding word *not* will
##   change to inform only about variables' declarations which can't be updated
##   to let or const.
## * varUplevel is the name of the rule. It is case-insensitive, thus it can be
##   set as *varuplevel*, *varUplevel* or *vArUpLeVeL*.
##
## Disabling the rule
## ------------------
## It is possible to disable the rule for a selected part of the checked code
## by using pragma *ruleOff: "varUplevel"* in the element from which the rule
## should be disabled or in code before it. For example, if the rule should
## be disabled for variable `var i = 1`, the full declaration of it can be::
##
##     var i {.ruleOff: "varUplevel".} = 1
##
## To enable the rule again, the pragma *ruleOn: "varUplevel"* should be added in
## the element which should be checked or in the code before it. For example,
## if the rule should be re-enabled for `const a = 1`, the full declaration
## should be::
##
##     const a {.ruleOn: "varUplevel".} = 1
##
## Examples
## --------
##
## 1. Check if any declaration of local variable can be updated::
##
##     check varUplevel
##
## 2. Search for declarations of local variables which can't be updated::
##
##     search not varUplevel

# Import default rules' modules
import ../rules

ruleConfig(ruleName = "varuplevel",
  ruleFoundMessage = "declarations which can{negation}{rule.options[0]} be upgraded",
  ruleNotFoundMessage = "declarations which can{negation}{rule.options[0]} be upgraded not found.")

checkRule:
  initCheck:
    discard
  startCheck:
    discard
  checking:
    discard
  endCheck:
    let negation: string = (if rule.negation: "'t" else: "")
