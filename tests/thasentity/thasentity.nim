discard """
  exitcode: 0
  output: '''FATAL The rule hasEntity accepts two, three or four options, but not enough of them are supplied: ''.
NOTICE Doesn't have declared nkProcDef with name 'MyProc'.
ERROR Has declared nkProcDef with name 'MyProc' at line: 1.
NOTICE Doesn't have declared nkProcDef with name 'MyProc'.
NOTICE Has declared nkProcDef with name 'MyProc' at line: 1.
NOTICE Doesn't have declared nkProcDef with name 'MyProc'.
NOTICE Declared nkProcDef with name 'MyProc' found: 0
NOTICE Declared nkProcDef with name 'MyProc' found: 1
NOTICE Declared nkProcDef with name 'MyProc' found: 1
NOTICE Declared nkProcDef with name 'MyProc' found: 0'''
"""

import ../../src/rules/hasentity
import ../helpers.nim

const
  validOptions = @["nkProcDef", "MyProc"]
  invalidOptions = @[""]
  invalidNimCode = "quit"
  validNimCode = "proc MyProc() = discard"

runRuleTest()
