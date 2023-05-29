discard """
  exitcode: 0
  output: '''FATAL The rule namingconv requires at least 2 options, but only 0 provided: ''.
ERROR name of 'IsThe' line: 1 doesn't follow naming convention.
ERROR name of 'isThe' line: 1 follow naming convention.
NOTICE Declarations which follow naming convention not found.
NOTICE name of 'isThe' line: 1 follow naming convention.
NOTICE Declarations which not follow naming convention not found.
NOTICE name of 'IsThe' line: 1 doesn't follow naming convention.
NOTICE Declarations which follow naming convention found: 0
NOTICE Declarations which follow naming convention found: 1
NOTICE name of 'IsThe' line: 1 doesn't follow naming convention.
NOTICE Declarations which not follow naming convention found: 1
NOTICE Declarations which not follow naming convention found: 0
The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/namingconv
import ../helpers.nim

const
  validOptions = @["variables", "[a-z][a-zA-Z0-9_]"]
  invalidOptions = @[]
  invalidNimCode = "var IsThe: int = 1"
  validNimCode = "var isThe: int = 1"

runRuleTest(disabledChecks = {fixTests})
