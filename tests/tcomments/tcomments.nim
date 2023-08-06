discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule comments requires at maximum 2 options, but 3 provided: 'randomoption, anotheroption, thirdoption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: Comment at line: 2 doesn't match the pattern '^FIXME.*'.
INFO: Checking check type of the rule with the valid code.
ERROR: Comment at line: 2 doesn't match the pattern '^FIXME.*'.
INFO: Checking negative check type of the rule with the valid code.
ERROR: Comment at line: 1 match the pattern '^FIXME.*'.
INFO: Checking negative check type of the rule with the invalid code.
ERROR: Comment at line: 1 match the pattern '^FIXME.*'.
INFO: Checking search type of the rule with the invalid code.
NOTICE: Comment at line: 1 match the pattern '^FIXME.*'.
INFO: Checking search type of the rule with the valid code.
NOTICE: Comment at line: 1 match the pattern '^FIXME.*'.
INFO: Checking negative search type of the rule with the valid code.
NOTICE: Comment at line: 2 doesn't match the pattern '^FIXME.*'.
NOTICE: Comments which doesn't match the pattern not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: Comment at line: 2 doesn't match the pattern '^FIXME.*'.
NOTICE: Comments which doesn't match the pattern not found.
INFO: Checking count type of the rule with the invalid code.
NOTICE: Comments which match the pattern found found: 1
INFO: Checking count type of the rule with the valid code.
NOTICE: Comments which match the pattern found found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: Comment at line: 2 doesn't match the pattern '^FIXME.*'.
NOTICE: Comments which doesn't match the pattern found found: 0
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Comment at line: 2 doesn't match the pattern '^FIXME.*'.
NOTICE: Comments which doesn't match the pattern found found: 0
INFO: Checking fix type of the rule.
ERROR: Comment at line: 2 doesn't match the pattern '^FIXME.*'.
INFO: Checking negative fix type of the rule.
ERROR: Comment at line: 1 match the pattern '^FIXME.*'.'''
"""

import ../../src/rules/comments
import ../helpers.nim

const
  validOptions: seq[string] = @["pattern", "^FIXME.*"]
  invalidOptions = @["randomoption", "anotheroption", "thirdoption"]
  invalidNimCode = "var a = 1"
  validNimCode = "var a = 1"

runRuleTest()
