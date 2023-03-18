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

## Provides various code used in other modules

# Standard library imports
import std/[logging, tables]
# External modules imports
import contracts
# Internal modules imports
import rules, pragmas
# Nimalyzer rules imports
import rules/[hasdoc, hasentity, haspragma, namedparams, paramsused, vardeclared]

{.push ruleOff: "varDeclared".}
const rulesList* = {haspragma.ruleName: (haspragma.ruleCheck,
    haspragma.validateOptions), hasentity.ruleName: (hasentity.ruleCheck,
    hasentity.validateOptions), paramsused.ruleName: (paramsused.ruleCheck,
    paramsused.validateOptions), namedparams.ruleName: (
    namedparams.ruleCheck, namedparams.validateOptions), hasdoc.ruleName: (
    hasdoc.ruleCheck, hasdoc.validateOptions), varDeclared.ruleName: (
    varDeclared.ruleCheck, varDeclared.validateOptions)}.toTable
{.push ruleOn: "varDeclared".}

proc message*(text: string; level: Level = lvlInfo) {.raises: [], tags: [
    RootEffect], contractual.} =
  ## Log the selected message. If error happens during logging, print the
  ## error message and quit the program
  ##
  ## * text  - the message to log
  ## * level - the log level of the message. Default value is lvlInfo
  require:
    text.len > 0
  body:
    try:
      log(level = level, args = text)
    except Exception:
      echo "Can't log the message. Reason: ", getCurrentExceptionMsg()
      echo "Stopping nimalyzer"
      quit QuitFailure

proc abortProgram*(message: string; e: ref Exception = nil) {.gcsafe,
    raises: [], tags: [RootEffect], contractual.} =
  ## Log the message and stop the program
  ##
  ## * message - the message to log
  ## * e       - the exception which occured if any.
  require:
    message.len > 0
  body:
    discard errorMessage(text = message, e = e)
    message(text = "Stopping nimalyzer.")
    quit QuitFailure
