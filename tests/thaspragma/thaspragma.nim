discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule haspragma requires at least 2 options, but only 0 provided: ''.
INFO: Checking check type of the rule with the invalid code.
ERROR: rule: haspragma, procedure MyProc line: 1 doesn't have declared any pragmas.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: rule: haspragma, procedure MyProc line: 1 has declared pragma: raises: [].
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: rule: haspragma, The selected pragma(s) not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: rule: haspragma, procedure MyProc line: 1 has declared pragma: raises: [].
INFO: Checking negative search type of the rule with the valid code.
NOTICE: rule: haspragma, The selected pragma(s) not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: rule: haspragma, procedure MyProc line: 1 doesn't have declared any pragmas.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Declared procedures with selected pragmas found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Declared procedures with selected pragmas found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: Declared procedures with selected pragmas found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Declared procedures with selected pragmas found: 0
INFO: Checking fix type of the rule.
ERROR: rule: haspragma, procedure MyProc line: 1 doesn't have declared pragma: raises: [].
INFO: Checking negative fix type of the rule.
ERROR: rule: haspragma, procedure MyProc line: 1 has declared pragma: raises: [].'''
"""

import ../../src/rules/haspragma
import ../helpers.nim

const
  validOptions = @["procedures", "raises: []"]
  invalidOptions = @[]
  invalidNimCode = "proc MyProc() = discard"
  validNimCode = "proc MyProc() {.raises: [].} = discard"

runRuleTest()
