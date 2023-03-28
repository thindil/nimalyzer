discard """
  exitcode: 0
  output: '''FATAL The rule hasDoc doesn't accept any options, but options suplied: 'randomoption'.
ERROR Module doesn't have documentation.
ERROR Module has documentation.
NOTICE The documentation not found.
NOTICE Module has documentation.
NOTICE The documentation not found.
NOTICE Module doesn't have documentation.
NOTICE Declared public items with documentation found: 0
NOTICE Declared public items with documentation found: 1
NOTICE Module doesn't have documentation.
NOTICE Declared public items with documentation found: 1
NOTICE Declared public items with documentation found: 0'''
"""

import ../../src/rules/hasdoc
import ../helpers.nim

const
  validOptions = @[]
  invalidOptions = @["randomoption"]
  invalidNimCode = "quit"
  validNimCode = "## Doc"

runRuleTest()
