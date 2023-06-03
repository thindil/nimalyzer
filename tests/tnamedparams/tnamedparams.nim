discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule namedparams requires at maximum 0 options, but 1 provided: 'randomoption'.
INFO: Checking check type of the rule.
ERROR: call quit line: 1 doesn't have named parameter number: 1'.
INFO: Checking negative check type of the rule.
ERROR: call myProc line: 1 doesn't have named parameter number: 1'.
INFO: Checking search type of the rule.
NOTICE: Calls which have all named parameters not found.
NOTICE: call myProc line: 1 doesn't have named parameter number: 1'.
INFO: Checking negative search type of the rule.
NOTICE: Calls which not have all named parameters not found.
NOTICE: call quit line: 1 doesn't have named parameter number: 1'.
INFO: Checking count type of the rule.
NOTICE: Calls which have all named parameters found: 0
NOTICE: Calls which have all named parameters found: 1
INFO: Checking negative type of the rule.
NOTICE: call quit line: 1 doesn't have named parameter number: 1'.
NOTICE: Calls which not have all named parameters found: 1
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
