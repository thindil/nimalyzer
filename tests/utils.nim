include ../src/utils
import utils/helpers
import unittest2

suite "Unit tests for utils module":

  checkpoint "Initializing the tests"
  setLogger()

  test "Test showing message":
    message("Test message")
