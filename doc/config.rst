=========================
Configuration file syntax
=========================

.. default-role:: code
.. contents::

General information
===================

- All lines which start with hash sign (#) are treated as comments and ignored by the program.
- The configuration doesn't need to be in exact order, but some entries are required by the program to run.
- All names of settings are case-sensitive, thus, it must be *verbosity* or *output* and not *Verbosity* or *OUTPUT*.
- The list of available program's rules is available in the project's documentation.

Available settings
==================

Verbosity
---------

The minimal level of messages which will be shown in the program output. It is
an optional parameter. If not set, the program will be show only the standard
messages. The message about starting the program, will always be shown as it
is set before setting the level of verbosity. The setting below sets the verbosity
level to show all, even debug messages. For names of levels, the
program uses the Level enumeration values from the standard Nim logging
module.
::
    verbosity lvlAll

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

Source
------
The path to the file which will be analyzed. The path must be in Unix form.
It will be converted to the proper path by the program. A configuration file
must have at least one source file defined. You can add more than one source
setting per file. Also, the path can be absolute or relative. In the second
form, the path must be relative to the place from which nimalyzer is
executed (working directory).
::
    source src/nimalyzer.nim
    source src/pragmas.nim
    source src/rules.nim
    source tools/gendoc.nim

Files
-----
The pattern of path for the list of files which will be analyzed. The path
must be in Unix form. It will be converted to the proper path by the
program. A configuration file must have at least one source file defined, by
'source', 'files' or 'directory' settings. You can add more than one files
setting per file. Also, the path can be absolute or relative. In the second
form, the path must be relative to the place from which nimalyzer is
executed (working directory). The setting below do exactly the same what the
settings above.
::
    files src/*.nim
    files tools/*.nim

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

Check rules
-----------
Check rules are rules, which when violated by the source code, will produce the
program error by nimalyzer. The syntax is: check ?not? [nameOfTheRule]
[parameters], where nameOfTheRule is mandatory and requirement for parameters
depends on the rule. Name of the rule to check must be one of defined in the
program, but it is case-insensitive in a configuration file. HasPragma is
equal to haspragma or hasPRAGMA. If the optional word "not" is present, the
program will check the rule in opposite direction. For example, rule
hasPragma will check if procedures doesn't have the selected pragmas. The
message's level for info about the line of code which violates the rule is
lvlError. The setting below checks if all procedures in the source code have
pragma "contractual", "raises" and "tags". The last two can be empty or have
listed values. The second rule checks if all parameters of all procedures are
used in the code. The third rule checks if all calls in the code uses named
parameters. The fourth rule checks if all public declarations have
documentation. The fifth rule checks if all variables' declarations have
declared type and value for them.
::
    check hasPragma contractual "raises: [*" "tags: [*"
    check paramsUsed
    check namedParams
    check hasDoc
    check varDeclared full

Search rules
------------
Search rules are similar to the check rules. The main difference is that they
usually returns information about the line in source code which meet the rule
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
always returns success, no matter how many results are found. Another
difference is, that they return only the amount of results which meet the
rule requirements. The syntax is count ?not? [nameOfTheRule] [parameters].
All requirements for setting a count rule are the same as for check rules,
written above. The message's level for info about amount of the results which
meet the rule's requirements is lvlNotice. The setting below will look for
procedures with not declared pragma "contractual" and returns the amount
of results found.
::
    count not hasPragma contractual
