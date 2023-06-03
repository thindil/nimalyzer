discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule hasentity requires at least 2 options, but only 1 provided: ''.
INFO: Checking check type of the rule.
ERROR: Doesn't have declared nkProcDef with name 'MyProc'.
INFO: Checking negative check type of the rule.
ERROR: Has declared nkProcDef with name 'MyProc' at line: 1.
INFO: Checking search type of the rule.
ERROR: Doesn't have declared nkProcDef with name 'MyProc'.
NOTICE: Has declared nkProcDef with name 'MyProc' at line: 1.
INFO: Checking negative search type of the rule.
NOTICE: Doesn't have declared nkProcDef with name 'MyProc'.
INFO: Checking count type of the rule.
NOTICE: Declared nkProcDef with name 'MyProc' found: 0
NOTICE: Declared nkProcDef with name 'MyProc' found: 1
INFO: Checking negative type of the rule.
NOTICE: Declared nkProcDef with name 'MyProc' found: 1
NOTICE: Declared nkProcDef with name 'MyProc' found: 0
INFO: Checking fix type of the rule.
INFO: The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/hasentity
import ../helpers.nim

const
  validOptions = @["nkProcDef", "MyProc"]
  invalidOptions = @[""]
  invalidNimCode = "quit"
  validNimCode = "proc MyProc() = discard"

runRuleTest(disabledChecks = {fixTests})
