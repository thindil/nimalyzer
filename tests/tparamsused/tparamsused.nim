discard """
  exitcode: 0
  output: '''FATAL The option for the rule paramsUsed must be type of enties to check, but got: 'randomoption'.
ERROR procedure MyProc line: 1 doesn't use parameter 'arg'.
NOTICE Procedures which uses all parameters not found.
NOTICE Procedures which not uses all parameters not found.
NOTICE procedure MyProc line: 1 doesn't use all parameters.
NOTICE Procedures which uses all parameters found: 0
NOTICE Procedures which uses all parameters found: 1
NOTICE procedure MyProc line: 1 doesn't use all parameters.
NOTICE Procedures which not uses all parameters found: 1
NOTICE Procedures which not uses all parameters found: 0'''
"""

import ../../src/rules/paramsused
import ../helpers.nim

const
  validOptions = @["procedures"]
  invalidOptions = @["randomoption"]
  invalidNimCode = "proc MyProc(arg: int) = discard"
  validNimCode = "proc MyProc(arg: int) = echo $arg"

runRuleTest()
