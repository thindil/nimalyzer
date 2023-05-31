discard """
  exitcode: 0
  output: '''FATAL The rule haspragma requires at least 2 options, but only 0 provided: ''.
ERROR procedure MyProc line: 1 doesn't have declared any pragmas.
ERROR procedure MyProc line: 1 has declared pragma: raises: [].
NOTICE The selected pragma(s) not found.
NOTICE procedure MyProc line: 1 has declared pragma: raises: [].
NOTICE The selected pragma(s) not found.
NOTICE procedure MyProc line: 1 doesn't have declared any pragmas.
NOTICE Declared procedures with selected pragmas found: 0
NOTICE Declared procedures with selected pragmas found: 1
NOTICE Declared procedures with selected pragmas found: 1
NOTICE Declared procedures with selected pragmas found: 0
ERROR procedure MyProc line: 1 doesn't have declared pragma: raises: [].
ERROR procedure MyProc line: 1 has declared pragma: raises: [].'''
"""

import ../../src/rules/haspragma
import ../helpers.nim

const
  validOptions = @["procedures", "raises: []"]
  invalidOptions = @[]
  invalidNimCode = "proc MyProc() = discard"
  validNimCode = "proc MyProc() {.raises: [].} = discard"

runRuleTest()
