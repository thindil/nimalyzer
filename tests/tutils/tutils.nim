discard """
  exitcode: 1
  outputsub: "Test message"
"""

import ../../src/utils
import ../helpers

setLogger()

message("Test message")
abortProgram("Test result")
