discard """
  exitcode: 0
  output: '''FATAL The rule varDeclared require type of declaration as the option, but nothing was supplied.
ERROR declaration of 'i' line: 1 doesn't set type for the variable.
ERROR declaration of i line: 1 sets the type 'int' as the type of the variable.
NOTICE Declarations withtype declaration not found.
NOTICE declaration of i line: 1 sets the type 'int' as the type of the variable.
NOTICE Declarations withouttype declaration not found.
NOTICE declaration of 'i' line: 1 doesn't set type for the variable.
NOTICE Declarations withtype declaration found: 0
NOTICE Declarations withtype declaration found: 1
NOTICE declaration of 'i' line: 1 doesn't set type for the variable.
NOTICE Declarations withouttype declaration found: 1
NOTICE Declarations withouttype declaration found: 0'''
"""

import ../../src/rules/vardeclared
import ../helpers.nim

const
  validOptions = @["type"]
  invalidOptions = @[]
  invalidNimCode = "var i = 1"
  validNimCode = "var i: int = 1"

runRuleTest()
