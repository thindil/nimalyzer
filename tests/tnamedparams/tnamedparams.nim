discard """
  exitcode: 0
  output: '''FATAL The rule namedparams requires at maximum 0 options, but 1 provided: 'randomoption'.
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
NOTICE Calls which not have all named parameters found: 0
The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/namedparams
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "quit(QuitSuccess)"
  validNimCode = "myProc(named = true)"

runRuleTest(disabledChecks = {fixTests})
