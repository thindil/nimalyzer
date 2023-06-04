discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule paramsused option number 1 has invalid value: 'randomoption'.
INFO: Checking check type of the rule.
ERROR: procedure MyProc line: 1 doesn't use parameter 'arg'.
INFO: Checking negative check type of the rule.
ERROR: procedure MyProc line: 1 use all parameters.
INFO: Checking search type of the rule.
NOTICE: Procedures which uses all parameters not found.
NOTICE: procedure MyProc line: 1 use all parameters.
INFO: Checking negative search type of the rule.
NOTICE: Procedures which not uses all parameters not found.
NOTICE: procedure MyProc line: 1 doesn't use all parameters.
INFO: Checking count type of the rule.
NOTICE: Procedures which uses all parameters found: 0
NOTICE: Procedures which uses all parameters found: 1
INFO: Checking negative type of the rule.
NOTICE: procedure MyProc line: 1 doesn't use all parameters.
NOTICE: Procedures which not uses all parameters found: 1
NOTICE: Procedures which not uses all parameters found: 0
INFO: Checking fix type of the rule.
INFO: The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/paramsused
import ../helpers.nim

const
  validOptions = @["procedures"]
  invalidOptions = @["randomoption"]
  invalidNimCode = "proc MyProc(arg: int) = discard"
  validNimCode = "proc MyProc(arg: int) = echo $arg"

runRuleTest(disabledChecks = {fixTests})
