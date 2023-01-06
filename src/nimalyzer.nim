# Copyright © 2023 Bartek Jasicki <thindil@laeran.pl>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS AND CONTRIBUTORS ''AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## This is the main module of the program.

# Standard library imports
import std/[logging, os]
# External modules imports
# Internal imports

proc main() =
  # Set the logger, where the program output will be send
  let logger = newConsoleLogger(fmtStr = "[$time] - $levelname: ")
  logger.log(lvlInfo, "Starting nimalyzer ver 0.1.0")
  # No configuration file specified, quit from the program
  if paramCount() == 0:
    logger.log(lvlError, "No configuration file specified. Please run the program with path to the config file as an argument.")
    logger.log(lvlInfo, "Stopping nimalyzer.")
    quit QuitFailure
  # Read the configuration file and set the program
  let configFile = paramStr(i = 1)
  try:
    for line in configFile.lines:
      echo line
  except IOError:
    logger.log(lvlError, "The specified configuration file '" & configFile & "' doesn't exist.")
    logger.log(lvlInfo, "Stopping nimalyzer.")
    quit QuitFailure
  logger.log(lvlInfo, "Stopping nimalyzer.")

when isMainModule:
  main()
