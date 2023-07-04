=======================
Nimalyzer documentation
=======================

General information
===================

Nimalyzer is a static code analyzer for `Nim <https://github.com/nim-lang/Nim>`_
programming language. It allows checking a Nim source code against predefined
rules. Its design is inspired by `AdaControl <https://www.adalog.fr/en/adacontrol.html>`_.
Nimalyzer can be used to enforce some design patterns or ensure that some
language constructs are present in a code, or not. For example, it can check if
all procedures have defined proper pragmas. Additionally, it can be used as an
advanced search through a code tool, for example find all public variables type
of *int* with name which starts with *newVar*. It is controlled by
configuration files containing a set of rules, their parameters and options
related to the program behavior. At this moment, the project is in early alpha
stage, it doesn't offer too much, its configuration syntax can change and
should have a nice amount of bugs.

The project released under 3-Clause BSD license.

Usage
=====

1. To use Nimalyzer with your project, first you have to create a configuration
   file for it. Please check documentation for `configuration syntax <configuration.html>`_
   and list of `available rules <available_rules.html>`_ for more details. In your
   configuration file you have to set at least one source file to check and at
   least one rule to use.

2. Run Nimanalyzer with path to your configuration file as the argument. For example:
   `nimalyzer config/nimalyzer.cfg` and read its output.

Disabling rules
===============

It is possible to disable a selected rule for a part of a module with the pragma
*ruleOff: [name of pragma]* and re-enable it later with the pragma *ruleOn:
[name of pragma]*. To do it you have to:

1. Import the module *pragmas* from *nimalyzer*: `import nimalyzer/pragmas`

2. Insert in the desired place in the code the pragma to disable rule. For
   example: `{.ruleOff: "hasDoc".}`. Usualy, the pragma can be placed before or
   in the fragment of the code in which it should be disabled, but some rules
   can enter restrictions about it. Please refer to the rules' documentation
   where to place the pragma.

3. If you want to re-enable a rule in a code later, insert pragma ruleOn. For
   example: `{.ruleOn: "hasDoc".}`. Same as with disabling, the pragma can be
   placed before or in the fragment of the code in which it should be disabled,
   but some rules can enter restrictions about it. Please refer to the rules'
   documentation where to place the pragma. Usually, rules require it in the
   same location where pragma *ruleOff* should be placed.

Notes
-----

* Names of the rules used for pragmas are case-insensitive, thus "hasDoc" can
  be also "hasdoc", "HasDoc" or "HASDOC".
* Names of the rules used for pragmas are strings, compared to the value of
  `ruleName` constants defined in the rules.
* Disabling the rule in the code cause to disable all checks of that type in
  the code. For example if you used `{.ruleOff: "hasEntity".}` and your
  configuration file contains several settings for that rule, all of them will
  be disabled from this point in the code.

Fix type of rules
=================

The program allows to automatically or semi-automatically fix some problems
reported by its rules with `fix` type of the rule. In most cases, this type of
rules will only open the source code file with the default text editor or
execute another command set in the program's configuration file. But several
rules allow to automatically fix the problems, for example, *hasPragma* rule
can add or remove a selected pragmas from declarations. In that case the
changes will be made on the same file. Sometimes it can produce an invalid
code, for example adding pragma **contractual** may produce an invalid code as
the pragma requires enclosing a code in special blocks. Thus, it is strongly
recommended to have some kind of backup of the code, for example a version
control system like Git, Fossil, etc. More information on how the selected
program's rule react with `fix` type of the rule can be found in the
`available rules documentation <available_rules.html>`_. Additionally, because
the program works on AST representation of the checked code, there is a big
chance that the code will be reformatted after changes. It is a good idea to
have set auto-formatting after executing `fix` type of rules.

Adding or removing rules
========================

All the program's rules are stored in *rules* directory inside *src*
directory. To add a new rule it is recommended to use tool **genrule** (or
**genrule.exe** on Windows). To create the tool, execute in the main project's
directory, where Nimble file is: `nimble tools`. Then execute command:
`bin/genrule`. The program will ask a couple of questions, create a new rule
from the template file located in *tools* directory and update the list of
rules in file *rulesList.txt* in *rules* directory. Now you can start working
on your new rule.

To delete an existing rule, it is enough to remove its name from the list in
the file *rulesList.txt* in *rules* directory inside *src* directory. But
deleting the Nim file which contains the rule code is good too. Otherwise, when
a new rule will be added with **genrule** tool, it will re-add the deleted rule
to the list.

The structure of a rule's code
==============================

Each module which contains code of the program's rules is split on several
parts.

ruleConfig
----------

`ruleConfig` contains configuration of the rule. Available settings are:

* `ruleName` - the name of the rule. Required.
* `ruleFoundMessage` - the message shown when the rule return positive
  result of analyzing the code. Required.
* `ruleNotFoundMessage` - the message shown when the rule returns negative
  result of analyzing the code. Required.
* `rulePositiveMessage` - the message shown when the rule meet the code's
  element which follows the rule's requirements, for example, a procedure with
  documentation, etc. Required.
* `ruleNegativeMessage` - the message shown when the rule meet the code's
  element which doesn't follow the rule's requirements, for example, a
  procedure without documentation, etc. Required.
* `ruleOptions` - the list of options which the rule accepts. If not set,
  default value, the rule will not accept any arguments in a
  configuration file. It is a Nim sequence with possible values: `node` for
  AST Node, `str` for string values, `int` for integer values and `custom`
  for string values which can contain only the selected values, similar to
  enumerations. In the last case the setting `ruleOptionValues` must be set
  too. At the moment a rule can have only one `custom` option type. The
  setting is optional.
* `ruleOptionValues` - the list of values for the `custom` type of the rule's
  options. It is a Nim sequence of strings. The setting is required only
  when setting `ruleOptions` contains `custom` type of the options.
* `ruleMinOptions` - the minimal amount of options required by the rule.
  Default value is 0, which means the rule requires zero or more options. The
  setting is optional.
* `ruleShowForCheck` - if true, show the rule summary message for **check**
  type of the rule. By default it is disabled, default falue *false*. The
  setting is optional.

checkRule
---------

`checkRule` is the macro which is runs to check the Nim code. It is split on
several parts. Each part must have at least `discard` statement. All the
checking parts are:

* `initCheck` - the initialization of checking the Nim code with the rule. This
  part of code is run only once. It is a good place to initialize some global
  variables, etc.
* `startCheck` - the fragment which will be executed each time, before check any
  AST node of the Nim code.
* `checking` - the part in which the Nim code is checked. Executed for each AST
  node of the Nim code.
* `endCheck` - the part executed at the end of checking, same as `initCheck`,
  executed only once. It shows the rule's summary, etc.
