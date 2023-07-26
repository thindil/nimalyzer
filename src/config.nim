# Copyright © 2023 Bartek Jasicki
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

## Provides code for parse the program's configuration file

# Standard library imports
import std/[os, parseopt, sequtils]
# Internal modules imports
import rules, utils

type
  ConfigKind* = enum
    ## The types of configuration entries: a program's rule or a custom message
    rule, message

  ConfigData* = object
    ## Contains information about the configuration of the program's rule
    ##
    ## * name            - The name of the rule
    ## * options         - The options list provided by the user in a configuration
    ##                     file
    ## * negation        - If true, the rule is negation
    ## * ruleType        - The type of the rule
    ## * index           - The index of the rule
    ## * forceFixCommand - If true, force use setting fixCommand for the rule
    ##                     instead of the rule's fix code
    case kind*: ConfigKind
    of rule:
      name*: string
      options*: seq[string]
      negation*: bool
      ruleType*: RuleTypes
      index*: int
      forceFixCommand*: bool
    of message:
      text*: string

const fixCommand: string = when defined(macos) or defined(macosx) or defined(
    windows): "open" else: "xdg-open" & " {fileName}"
    ## The command executed when a fix type of rule encounter a problem. By
    ## default it try to open the selected file in the default editor.

proc parseConfig*(configFile: string; sections: var int): tuple[sources: seq[
    string]; rules: seq[ConfigData]; fixCommand: string;
    maxReports: Natural] {.sideEffect, raises: [], tags: [ReadIOEffect,
    RootEffect], contractual.} =
  ## Parse the configuration file and get all the program's settings
  ##
  ## * configFile - the path to the configuration file which will be parsed
  ## * sections   - the amount of sections in the configuration file. The
  ##                sections are separated with *reset* setting in the file.
  ##
  ## Returns tuple with the list of source code files to check, the list of
  ## the program's rules to check plus custom messages to show, and the command
  ## executed when rule doesn't set own code for fix type of rules. Also
  ## returns the updated parameter sections. If the file was fully parsed, the
  ## parameter sections will have value -1. Otherwise, the parameter sections
  ## will be the number of the setting *reset* in the configuration file, so
  ## next time the procedure can start parsing from exactly this setting.
  require:
    configFile.len > 0
  body:

    proc addFile(fileName: string; sources: var seq[string]) {.gcsafe, raises: [
        ], tags: [RootEffect], contractual.} =
      ## Add the selected file as a source code to check for the program
      ##
      ## * fileName - the path to the file which will be added
      ## * sources  - the list of source code files to check
      ##
      ## Returns the updated parameter sources
      require:
        fileName.len > 0
      body:
        if fileName notin sources:
          sources.add(y = fileName)
          message(text = "Added the file '" & fileName &
              "' to the list of files to check.", level = lvlDebug)
    result.fixCommand = fixCommand
    result.maxReports = Positive.high
    try:
      # Read the program's configuration
      var
        configSection: int = sections
        forceFixCommand: bool = false
      for line in configFile.lines:
        let lowerLine: string = line.toLowerAscii()
        # Comment line, skip
        if line.startsWith(prefix = '#') or line.len == 0:
          continue
        # If the configuration file contains a couple of sections of settings,
        # skip the current line until don't meet the proper section
        elif configSection > 0:
          if lowerLine != "reset":
            continue
          else:
            configSection.dec
            message(text = "Restarting parsing of the configuration file.",
                level = lvlDebug)
            continue
        # If the configuration file contains "reset" setting, stop parsing it
        # and increase the amount of sections
        elif lowerLine == "reset":
          sections.inc
          message(text = "Stopped parsing of the configuration file.",
              level = lvlDebug)
          return
        # Set the program's verbosity
        elif lowerLine.startsWith(prefix = "verbosity"):
          try:
            setLogFilter(lvl = parseEnum[Level](s = line[10..^1]))
            message(text = "Setting the program's verbosity to '" & line[
                10..^1] & "'.", level = lvlDebug)
          except ValueError:
            abortProgram(message = "An invalid value set in the configuration file for the program's verbosity level.")
        # Set the max amount of the reported problems
        elif lowerLine.startsWith(prefix = "maxreports"):
          try:
            result.maxReports = parseInt(s = line[11..^1])
            message(text = "Setting the program's max reports to " & line[
                11..^1] & ".", level = lvlDebug)
          except ValueError:
            abortProgram(message = "An invalid value set in the configuration file for the maximum amount of the program's reports.")
        # Set the file to which the program's output will be logged
        elif lowerLine.startsWith(prefix = "output"):
          let fileName: string = unixToNativePath(path = line[7..^1])
          addHandler(handler = newFileLogger(filename = fileName,
              fmtStr = "[$time] - $levelname: "))
          message(text = "Added the file '" & fileName & "' as a log file.",
              level = lvlDebug)
        # Set the command which will be executed when rule type fix encounter
        # a problem
        elif lowerLine.startsWith(prefix = "fixcommand"):
          result.fixCommand = line[11..^1]
          message(text = "The command to execute for fix rules' type set to '" &
              result.fixCommand & "'.", level = lvlDebug)
        # Set the source code file to check
        elif lowerLine.startsWith(prefix = "source"):
          let fileName: string = unixToNativePath(path = line[7..^1])
          addFile(fileName = fileName, sources = result.sources)
        # Set the source code files to check
        elif lowerLine.startsWith(prefix = "files"):
          try:
            for fileName in walkFiles(pattern = line[6..^1]):
              addFile(fileName = fileName, sources = result.sources)
          except OSError:
            abortProgram(message = "Can't parse the setting: '" & line &
                "'. Reason: ", e = getCurrentException())
        # Set the source code files to check, the second option
        elif lowerLine.startsWith(prefix = "directory"):
          try:
            for fileName in walkDirRec(dir = line[10..^1]):
              addFile(fileName = fileName, sources = result.sources)
          except OSError:
            abortProgram(message = "Can't add files to check. Reason: ",
                e = getCurrentException())
        # Set the message to show during the program's work
        elif lowerLine.startsWith(prefix = "message"):
          if line.len < 9:
            abortProgram(message = "Can't parse the 'message' setting in the configuration file. No message's text set.")
          let newMessage: ConfigData = ConfigData(kind: message, text: line[8..^1])
          result.rules.add(y = newMessage)
          message(text = "Added the custom message: '" & result.rules[^1].text &
              "' to the program's output.", level = lvlDebug)
        # Set do the progam should force its rules to execute the command instead
        # of code for fix type of rules
        elif lowerLine.startsWith(prefix = "forcefixcommand"):
          if line.len < 17:
            abortProgram(message = "Can't parse the 'forcefixcommand' setting in the configuration file. No value set, should be 0, 1, true or false.");
          if line[16..^1].toLowerAscii in ["0", "false"]:
            forceFixCommand = false
            message(text = "Disabled forcing the next rules to use a fix command instead of the code.",
                level = lvlDebug)
          else:
            forceFixCommand = true
            message(text = "Enabled forcing the next rules to use a fix command instead of the code.",
                level = lvlDebug)
        # Set the program's rule to test the code
        elif availableRuleTypes.anyIt(pred = lowerLine.startsWith(prefix = it)):
          var configRule: OptParser = initOptParser(cmdline = line)
          configRule.next
          let ruleType: RuleTypes = try:
              parseEnum[RuleTypes](s = configRule.key)
            except ValueError:
              none
          if ruleType == none:
            abortProgram(message = "Unknown type of the rule: '" &
                configRule.key & "'.")
          configRule.next
          var newRule: ConfigData = ConfigData(kind: rule,
              name: configRule.key.toLowerAscii, options: @[], negation: false,
              ruleType: ruleType, index: -1, forceFixCommand: forceFixCommand)
          if newRule.name == "not":
            newRule.negation = true
            configRule.next
            newRule.name = configRule.key.toLowerAscii
          for index, rule in rulesList.pairs:
            if rule.name == newRule.name:
              newRule.index = index
              break
          if newRule.index == -1:
            abortProgram(message = "No rule named '" & newRule.name & "' available.")
          while true:
            configRule.next()
            if configRule.kind == cmdEnd:
              break
            newRule.options.add(y = configRule.key)
          try:
            if not validateOptions(rule = rulesList[newRule.index],
                options = newRule.options):
              abortProgram(message = "Invalid options for rule '" &
                  newRule.name & "'.")
          except KeyError:
            abortProgram(message = "Can't validate the rule's parameters. Reason: ",
                e = getCurrentException())
          result.rules.add(y = newRule)
          message(text = "Added the" & (if result.rules[
              ^1].negation: " negation " else: " ") & $result.rules[
              ^1].ruleType & " rule '" & result.rules[^1].name &
              "' with options: '" & result.rules[^1].options.join(sep = ", ") &
              "' to the list of rules to check.", level = lvlDebug)
      sections = -1
    except IOError:
      abortProgram(message = "The specified configuration file '" & configFile & "' doesn't exist.")
