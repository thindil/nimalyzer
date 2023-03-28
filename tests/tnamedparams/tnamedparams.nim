discard """
  exitcode: 0
  output: '''FATAL The rule namedParams doesn't accept any options, but options suplied: 'randomoption'.
ERROR call quit line: 1 doesn't have named parameter number: 1'.
ERROR call myProc line: 1 doesn't have named parameter number: 1'.
NOTICE Calls which have all named parameters not found.
NOTICE call myProc line: 1 doesn't have named parameter number: 1'.
NOTICE Calls which not have all named parameters not found.
NOTICE call quit line: 1 doesn't have named parameter number: 1'.
NOTICE Calls which have all named parameters found: 0
NOTICE Calls which have all named parameters found: 1
NOTICE call quit line: 1 doesn't have named parameter number: 1'.
NOTICE Calls which not have all named parameters found: 1
NOTICE Calls which not have all named parameters found: 0'''
"""

import ../../src/rules/namedparams
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "quit(QuitSuccess)"
  validNimCode = "myProc(named = true)"

runRuleTest()
