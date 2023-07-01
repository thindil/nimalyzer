discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule namedparams requires at maximum 0 options, but 1 provided: 'randomoption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: call quit line: 1 doesn't have named parameter number: 1'.
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: call myProc line: 1 doesn't have named parameter number: 1'.
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: Calls which have all named parameters not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: call myProc line: 1 doesn't have named parameter number: 1'.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: Calls which not have all named parameters not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: call quit line: 1 doesn't have named parameter number: 1'.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Calls which have all named parameters found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Calls which have all named parameters found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: call quit line: 1 doesn't have named parameter number: 1'.
NOTICE: Calls which not have all named parameters found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Calls which not have all named parameters found: 0
INFO: Checking fix type of the rule.
INFO: The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/namedparams
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "quit(QuitSuccess)"
  validNimCode = "myProc(named = true)"

runRuleTest(disabledChecks = {fixTests})
