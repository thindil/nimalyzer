import std/logging
import compiler/[parser, trees]
import ../src/rules
import utils/helpers
import unittest2

suite "Unit tests for rules module":

  checkpoint "Initializing the tests"
  setLogger()

  var resultValue: int = 0

  test "Test showing message":
    checkpoint "Decreasing the value"
    message("Decrease value", resultValue)
    check:
      resultValue == -1
    checkpoint "Increasing the value"
    message("Increase value", resultValue, lvlInfo, false)
    check:
      resultValue == 0

  test "Test showing error message":
    try:
      var i: int8 = int8.high
      i.inc
    except OverflowDefect:
      check:
        errorMessage("Reason: ", getCurrentException()) == 0

  test "Test getting AST nodes to check":
    let
      (nimCache, nimConfig) = setNim()
      parentNode = parseString("""
      proc hello() =
        var a = 1
        for i in 1..2:
          echo a""", nimCache, nimConfig)
    check:
      getNodesToCheck(parentNode, parentNode[0][6]) == flattenStmts(parentNode)
