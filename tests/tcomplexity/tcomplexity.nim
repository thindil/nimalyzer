discard """
  exitcode: 0
  output: '''INFO: Checking the rule's options validation.
FATAL: The rule complexity requires at least 3 options, but only 2 provided: 'randomoption, anotheroption'.
INFO: Checking check type of the rule with the invalid code.
ERROR: rule: complexity, Code block at line: 1 has cyclomatic complexity more than 2 (3).
INFO: Checking check type of the rule with the valid code.
INFO: Checking negative check type of the rule with the valid code.
ERROR: rule: complexity, Code block at line: 1 has cyclomatic complexity less or equal to 2 (2).
INFO: Checking negative check type of the rule with the invalid code.
INFO: Checking search type of the rule with the invalid code.
NOTICE: rule: complexity, Code blocks with the complexity less or equal to the selected not found.
INFO: Checking search type of the rule with the valid code.
NOTICE: rule: complexity, Code block at line: 1 has cyclomatic complexity less or equal to 2 (2).
INFO: Checking negative search type of the rule with the valid code.
NOTICE: rule: complexity, Code blocks with the complexity more than the selected not found.
INFO: Checking negative search type of the rule with the invalid code.
NOTICE: rule: complexity, Code block at line: 1 has cyclomatic complexity more than 2 (3).
INFO: Checking count type of the rule with the invalid code.
NOTICE: Code blocks with the complexity less or equal to the selected found found: 0
INFO: Checking count type of the rule with the valid code.
NOTICE: Code blocks with the complexity less or equal to the selected found found: 1
INFO: Checking negative count type of the rule with the invalid code.
NOTICE: rule: complexity, Code block at line: 1 has cyclomatic complexity more than 2 (3).
NOTICE: Code blocks with the complexity more than the selected found found: 1
INFO: Checking negative count type of the rule with the valid code.
NOTICE: Code blocks with the complexity more than the selected found found: 0
INFO: Checking fix type of the rule.
INFO: The tests for fix type of rule are disabled.'''
"""

import ../../src/rules/complexity
import ../helpers.nim

const
  validOptions: seq[string] = @["cyclomatic", "all", "2"]
  invalidOptions = @["randomoption", "anotheroption"]
  invalidNimCode = """if i == 1 and b == 2:
  i = i + 1"""
  validNimCode = """if i == 1:
  i += 1"""

runRuleTest(disabledChecks = {fixTests})
