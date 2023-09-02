discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule hasentity requires at least 2 options, but only 1 provided: ''.
INFO: Checking check type of the rule with the invalid code.
ERROR: rule: hasentity, Doesn't have declared nkProcDef with name 'MyProc'.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: rule: hasentity, Has declared nkProcDef with name 'MyProc' at line: 1.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
ERROR: rule: hasentity, Doesn't have declared nkProcDef with name 'MyProc'.
INFO: Checking search type of the rule with the valid code.
NOTICE: rule: hasentity, Has declared nkProcDef with name 'MyProc' at line: 1.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: rule: hasentity, Doesn't have declared nkProcDef with name 'MyProc'.
INFO: Checking negative search type of the rule with the invalid code.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Declared nkProcDef with name 'MyProc' found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Declared nkProcDef with name 'MyProc' found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: Declared nkProcDef with name 'MyProc' found: 1
INFO: Checking negative count type of the rule with the valid code.
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
