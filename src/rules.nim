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

## Provides various things for the program rules

# Standard library imports
import std/logging
# External modules imports
import contracts

type

  RuleTypes* = enum
    ## the types of the program's rules
    none, check, search, count

  RuleOptions* = object ## Contains information for the program's rules
    options*: seq[string] ## The list of the program's rule
    parent*: bool ## If true, check is currently make in the parent (usualy module) entity
    fileName*: string ## The path to the file which is checked
    negation*: bool ## If true, the rule show return oposite result
    ruleType*: RuleTypes ## The type of rule
    amount*: int ## The amount of results found by the rule

proc message*(text: string; returnValue: var int; level: Level = lvlError;
    decrease: bool = true) {.gcsafe, raises: [], tags: [RootEffect],
    contractual.} =
  ## Log the rule's selected message
  ##
  ## * text        - the messages which will be logged
  ## * returnValue - the value returned by the rule, increased or decreased
  ## * level       - the log level of the message. Default value is lvlError
  ## * decrease    - if true, decrease returnValue, otherwise increase it. The
  ##                 default value is true
  ##
  ## Returns the updated parameter returnValue
  require:
    text.len > 0
  body:
    if decrease:
      returnValue.dec
    else:
      returnValue.inc
    try:
      log(level = level, args = text)
    except Exception:
      echo "Can't log the message. Reason: ", getCurrentExceptionMsg()
