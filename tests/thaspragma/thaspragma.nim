discard """
  exitcode: 0
  output: '''FATAL The rule hasPragma require type of entities to check and name(s) of pragma(s) as the option, but nothing was supplied.
ERROR procedure MyProc line: 1 doesn't have declared any pragmas.
ERROR procedure MyProc line: 1 has declared pragma: raises: [*.
NOTICE The selected pragma(s) not found.
NOTICE procedure MyProc line: 1 has declared pragma: raises: [*.
NOTICE The selected pragma(s) not found.
NOTICE procedure MyProc line: 1 doesn't have declared any pragmas.
NOTICE Declared procedures with selected pragmas found: 0
NOTICE Declared procedures with selected pragmas found: 1
NOTICE Declared procedures with selected pragmas found: 1
NOTICE Declared procedures with selected pragmas found: 0'''
"""

import ../../src/rules/haspragma
import ../helpers.nim

const
  validOptions = @["procedures", "raises: [*"]
  invalidOptions = @[]
  invalidNimCode = "proc MyProc() = discard"
  validNimCode = "proc MyProc() {.raises: [].} = discard"

runRuleTest()
