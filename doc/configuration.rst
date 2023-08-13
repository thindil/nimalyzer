=========================
Configuration file syntax
=========================

.. default-role:: code
.. contents::

General information
===================

- All lines which start with hash sign (#) are treated as comments and ignored by the program.
- The configuration doesn't need to be in exact order, but some entries are required by the program to run.
- All names of settings are case-insensitive, thus, it can be *verbosity* or *output* and *Verbosity* or *OUTPUT*.
- The list of available program's rules is available in the project's documentation.

Available settings
==================

Verbosity
---------
The minimal level of messages which will be shown in the program output. It is
an optional parameter. If not set, the program will be show only the standard messages.
The message about starting the program, will always be shown as it
is set before setting the level of verbosity. The setting below sets the verbosity
level to show all, even debug messages. For names of levels, the
program uses the Level enumeration values from the standard Nim logging
module.
::
    verbosity lvlAll

Reports limit
-------------
The maximum amount of the program's reports after which the program will stop working.
The reports means found violations of *check*, *fix* types of rules and any
findings for *search* rules. The summary of *count* rules doesn't count to the
limit. For example, setting this value to 20 will stop the program after it find
20 places in the code where a rule type *check* is violated. **NOTICE:** if
you reset the configuration with the `reset` setting, `maxReports` setting will
be reset too. The default value for the setting is max value for Nim integer,
around 4 billions.
::
    maxreports 20

Output
------
The path to the file in which the output of the program will be saved. It is
an optional parameter. If not set, the program's output will be only on the
console. The path must be in Unix form. It will be converted to the proper
path by the program. Also, the path can be absolute or relative. In the
second form, the path must be relative to the place from which nimalyzer is
executed (working directory). The moment from which the output will be saved
to the file depends on the position of this setting in the configuration
file. If you don't want to save any configuration related output, you can put
it at the end of the file.
::
    output nimalyzer.log

Fix rule command
----------------
The command which will be executed when the fix type of the program's rule
encounter a problem and the rule doesn't contain a code to automatically fix
it. It is an optional parameter. If not set, the program will try to open the
selected file in editor. Available parameters for the command are: {fileName}
which during execution will be replaced by the relative path to the currently checked
file, and {line} which will be replaced by the line in the code which
causes the problem. The rest of the setting will be used by the executed
program as an argument(s). The setting below will open the file in NeoVim.
::
    fixcommand nvim +{line} {fileName}

Force fix command
-----------------
If the setting is set to *true* or *1*, any subsequent program's rule will execute
the command sets with **fixcommand** setting or the default one instead of its fix
code. If the setting is set to *false* or *0*, following program's rules will
use their auto fix code or the command sets with the **fixcommand** setting if
they don't contain a code to automatically fix the checked code. The setting
below will force all the program's rules defined below to execute **fixcommand**
instead of their code.
::
    forcefixcommand true

Source
------
The path to the file which will be analyzed. The path must be in Unix form.
It will be converted to the proper path by the program. A configuration file
must have at least one source file defined. You can add more than one source
setting per file. Also, the path can be absolute or relative. In the second
form, the path must be relative to the place from which nimalyzer is
executed (working directory).
::
    source src/config.nim
    source src/nimalyzer.nim
    source src/pragmas.nim
    source src/rules.nim
    source src/utils.nim
    source tools/gendoc.nim
    source tools/genrule.nim

Directory
---------
The directory which content will be analyzed. The path must be in Unix form.
It will be converted to the proper path by the program. A configuration file
mush have at least one source file defined, by 'source', 'files' or
'directory' settings. You can add more than one directory setting per file.
Also, the path can be absolute or relative. In the second form, the path must
be relative to the place from which nimalyzer is executed (working directory).
The setting below will check all files in directory "src" and its
subdirectories.
::
    directory src

Message
-------
The message directive allows to add a message to the program's output during
its execution. The syntax is: message [text of the message]. The text doesn't
need to be enclosed with quotes. The first message added before adding any
of the program's rules is always threatened specially. It is added only once,
before the program starts checking the rules. Any message added after any
rule, will be repeated for each checked file. The setting below will show
the message in the program's output (console and the log file) only once.
::
    message Checking the program

Check rules
-----------
Check rules are rules, which when violated by the source code, will produce the
program error by nimalyzer. The syntax is: check ?not? [nameOfTheRule]
[parameters], where nameOfTheRule is mandatory and requirement for parameters
depends on the rule. Name of the rule to check must be one of defined in the
program, but it is case-insensitive in a configuration file. HasPragma is
equal to haspragma or hasPRAGMA. If the optional word "not" is present, the
program will check the rule in opposite direction. For example, rule
hasPragma will check if procedures doesn't have the selected pragmas. The message's
level for info about the line of code which violates the rule is
lvlError. The settings below checks for:

1.  If all procedures in the source code have pragma "contractual", "raises" and "tags". The last two can be empty or have listed values.
2.  If all parameters of all procedures are used in the code.
3.  If all parameters of all macros used in the code.
4.  If all calls in the code uses named parameters.
5.  If all public declarations and module have documentation, but without checking fields of objects' declarations.
6.  If all variables' declarations have declared type and value for them.
7.  If any local variable declaration can be updated to let or const.
8.  If any local variable declaration hides previously declared variable.
9.  If any `if` statement can be upgraded.
10. If any `for` statement uses iterators `pairs` or `items`.
11. If there are no empty `for` statements.
12. If all source code files have the legal header.
13. If any assignment can be updated to shorthand assignment.

::
    check hasPragma procedures contractual "raises: [*" "tags: [*"

Explanation
-----------
Explanation allows setting a message which will be shown to the user when the
program meets the code which violates the previously declared rule's settings.
It works only for check and fix types of rules. In that situation, the message
is included into the error information. The explanation setting should be always
declared after the program's rule declaration. Several consecutive explanation
settings will override the previous one, only the last is always taken. The
setting shouldn't contain a new line characters.
::
    explanation Contracts helps in testing the program and all declared procedures should have declared contracts for them. The procedures should avoid raising exceptions and handle each possible exception by themselves for greater stability of the program. The information about the effects system by tags pragma can also help in understanding what exactly the procedure doing.

    check paramsUsed procedures
    explanation Unused parameters only clutter the source code and can cause confusion.

    check paramsUsed macros
    explanation Unused parameters only clutter the source code and can cause confusion.

    check namedParams
    explanation Named parameters allow avoiding assigning invalid values to the calls but also allow to assing the calls' parameters in arbitrary order.

    check hasDoc all
    explanation The documentation is a love's letter to your future self. :) Documentation make our lives easier, especially if we have return to the code after a longer period of time.

    check varDeclared full
    explanation The full declaration of variables gives information about their types and sets the initial values for them which can prevent sometimes in hard to detect errors, when the default values change.

    check varUplevel
    explanation The proper usage of var, let and const types of declaration make the code more readable and prevent from invalid assigning to a variable which shouldn't be assigned.

    check localHides
    explanation If a local variable has the same name as a global one declared in the same scope, it can lead to hard to read code or even invalid assign to the variable.

    check ifStatements all
    explanation All the rules enabled make the code more readable. Empty statements are just a dead code. If the statement contains a finishing statment, like return or raise, then it is better to move its following brach outside the statement for better readability. Also using positive conditions in the starting expression helps in preventing in some logical errors.

    check not forStatements iterators
    explanation There is no need to write information about usage of pairs or items iterators, it can be read directly from the code from the first part of the for statement declaration.

    check forStatements empty
    explanation Empty statements are just a dead code which made the code harder to read.

    check comments legal
    explanation Each source code file should have the legal information, required by BSD-3 license.

    check assignments shorthand
    explanation Shorthand assignments are shorter to write and can be more readable, especially with long names of variables.

    check caseStatements min 3
    explanation Short case statements can be replaced by if statements for better readablity.

Search rules
------------
Search rules are similar to the check rules. The main difference is that they
usually return information about the line in source code which meet the rule
requirements. Another difference is, that they return the program's error if
nothing is found. The syntax is search ?not? [nameOfTheRule] [parameters].
All requirements for setting a search rule are the same as for check rules,
written above. The message's level for info about the line of code which
meet the rule's requirements is lvlNotice. The setting below will look for
procedures with names "message" in the source code and return information
about the file and line in which they are found.
::
    search hasEntity nkProcDef message

Count rules
-----------
Count rules are similar to the search rules. The main difference is that they
always return success, no matter how many results are found. Another
difference is, that they return only the amount of results which meet the
rule requirements. The syntax is count ?not? [nameOfTheRule] [parameters].
All requirements for setting a count rule are the same as for check rules,
written above. The message's level for info about amount of the results which
meet the rule's requirements is lvlNotice. The setting below will look for
procedures with not declared pragma "contractual" and returns the amount
of results found.
::
    count not hasPragma contractual

Fix rules
------------
Fix rules are similar to the check rules. The main difference is if they find
a problem, they will try to fix it. How exactly fixing works, depends on the
rule. You can find detailed information how that kind of the rule affects the checked
code in its documentation. There are two ways: either the rule will
try to change the code to fix the problem, or the command configured above
with option fixcommand will be executed. For more general information about
the fix type of rules, its limits and how it affects the code, please refer to
the main program's documentation. Another difference with check type of rules
is that the fix type returns false only when the checked code was
automatically changed by the rule. The syntax is fix ?not? [nameOfTheRule]
[parameters]. All requirements for setting a fix rule are the same as for check
rules, written above. The message's level for info about the line of
code which violates the rule's requirements is lvlError. The setting below
will look for procedures without pragma sideEffect in the source code and
add the pragma to any procedure which doesn't have it.
::
    fix hasPragma procedures sideEffect

Reset
-----
The reset setting is a special setting. It causes the program to resets its
whole configuration, so the new set of files with rules can be set in the
file. When the program encounters the reset setting during parsing, it stops
parsing and execute the selected settings. After finishing, the program will
return to parsing the configuration file and start parsing it right from the
last encountered reset option. For example, the setting below stops parsing
the configuration file, checks the code of the program and later sets the
settings for check the program's rules. The setting will also reset the
setting `maxReports` to its default value.
::
    reset

Files
-----
The pattern of path for the list of files which will be analyzed. The path
must be in Unix form. It will be converted to the proper path by the
program. A configuration file must have at least one source file defined, by
'source', 'files' or 'directory' settings. You can add more than one files
setting per file. Also, the path can be absolute or relative. In the second
form, the path must be relative to the place from which nimalyzer is
executed (working directory). The pattern below check all files with 'nim'
extension in "src/rules" directory.
::
    files src/rules/*.nim

Here is the list of check rules to check by the program in the second section
of the configuration. They are almost the same as for the previous list of
the check rules, but the first rule checks also templates and macros. We also
set again message to show it only once as there is no rules configured for
the program.
::
    message Checking the program's rules
    check hasPragma all contractual "raises: [*"
    explanation Contracts helps in testing the program and all declared procedures should have declared contracts for them. The procedures should avoid raising exceptions and handle each possible exception by themselves for greater stability of the program.

    check paramsUsed procedures
    explanation Unused parameters only clutter the source code and can cause confusion.

    check paramsUsed macros
    explanation Unused parameters only clutter the source code and can cause confusion.

    check namedParams
    explanation Named parameters allow avoiding assigning invalid values to the calls but also allow to assing the calls' parameters in arbitrary order.

    check hasDoc all
    explanation The documentation is a love's letter to your future self. :) Documentation make our lives easier, especially if we have return to the code after a longer period of time.

    check varDeclared full
    explanation The full declaration of variables gives information about their types and sets the initial values for them which can prevent sometimes in hard to detect errors, when the default values change.

    check varUplevel
    explanation The proper usage of var, let and const types of declaration make the code more readable and prevent from invalid assigning to a variable which shouldn't be assigned.

    check localHides
    explanation If a local variable has the same name as a global one declared in the same scope, it can lead to hard to read code or even invalid assign to the variable.

    check ifStatements all
    explanation All the rules enabled make the code more readable. Empty statements are just a dead code. If the statement contains a finishing statment, like return or raise, then it is better to move its following brach outside the statement for better readability. Also using positive conditions in the starting expression helps in preventing in some logical errors.

    check not forStatements iterators
    explanation There is no need to write information about usage of pairs or items iterators, it can be read directly from the code from the first part of the for statement declaration.

    check forStatements empty
    explanation Empty statements are just a dead code which made the code harder to read.

    check comments legal
    explanation Each source code file should have the legal information, required by BSD-3 license.

    check assignments shorthand
    explanation Shorthand assignments are shorter to write and can be more readable, especially with long names of variables.

    check caseStatements min 3
    explanation Short case statements can be replaced by if statements for better readablity.
