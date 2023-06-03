discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule haspragma requires at least 2 options, but only 0 provided: ''.
INFO: Checking check type of the rule.
ERROR: procedure MyProc line: 1 doesn't have declared any pragmas.
INFO: Checking negative check type of the rule.
ERROR: procedure MyProc line: 1 has declared pragma: raises: [].
INFO: Checking search type of the rule.
NOTICE: The selected pragma(s) not found.
NOTICE: procedure MyProc line: 1 has declared pragma: raises: [].
INFO: Checking negative search type of the rule.
NOTICE: The selected pragma(s) not found.
NOTICE: procedure MyProc line: 1 doesn't have declared any pragmas.
INFO: Checking count type of the rule.
NOTICE: Declared procedures with selected pragmas found: 0
NOTICE: Declared procedures with selected pragmas found: 1
INFO: Checking negative type of the rule.
NOTICE: Declared procedures with selected pragmas found: 1
NOTICE: Declared procedures with selected pragmas found: 0
INFO: Checking fix type of the rule.
ERROR: procedure MyProc line: 1 doesn't have declared pragma: raises: [].
INFO: Checking negative fix type of the rule.
ERROR: procedure MyProc line: 1 has declared pragma: raises: [].'''
"""

import ../../src/rules/haspragma
import ../helpers.nim

const
  validOptions = @["procedures", "raises: []"]
  invalidOptions = @[]
  invalidNimCode = "proc MyProc() = discard"
  validNimCode = "proc MyProc() {.raises: [].} = discard"

runRuleTest()
