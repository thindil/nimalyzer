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

* `ruleName` - the name of the rule. Required. String value.
* `ruleFoundMessage` - the message shown when the rule return positive
  result of analyzing the code. Required. String value.
* `ruleNotFoundMessage` - the message shown when the rule returns negative
  result of analyzing the code. Required. String value.
* `rulePositiveMessage` - the message shown when the rule meet the code's
  element which follows the rule's requirements, for example, a procedure with
  documentation, etc. Required. String value.
* `ruleNegativeMessage` - the message shown when the rule meet the code's
  element which doesn't follow the rule's requirements, for example, a
  procedure without documentation, etc. Required. String value.
* `ruleOptions` - the list of options which the rule accepts. If not set,
  default value, the rule will not accept any arguments in a
  configuration file. It is a Nim sequence with possible values: `node` for
  AST Node, `str` for string values, `int` for integer values and `custom`
  for string values which can contain only the selected values, similar to
  enumerations. In the last case the setting `ruleOptionValues` must be set
  too. At the moment a rule can have only one `custom` option type. The
  setting is optional. Enumeration.
* `ruleOptionValues` - the list of values for the `custom` type of the rule's
  options. It is a Nim sequence of strings. The setting is required only
  when setting `ruleOptions` contains `custom` type of the options.
* `ruleMinOptions` - the minimal amount of options required by the rule.
  Default value is 0, which means the rule requires zero or more options. The
  setting is optional. Natural value.
* `ruleShowForCheck` - if true, show the rule summary message for **check**
  type of the rule. By default it is disabled, default falue *false*. The
  setting is optional. Boolean value.

Constants
---------

Each rule has available following constants to use in its code:

* `showForCheck` - Boolean value, set by the configuration's option
  `ruleShowForCheck`.
* `foundMessage` - String value, set by the configuration's option
  `ruleFoundMessage`.
* `notFoundMessage` - String value, set by the configuration's option
  `ruleNotFoundMessage`.
* `positiveMessage` - String value, set by the configuration's option
  `rulePositiveMessage`.
* `negativeMessage` - String value, set by the configuration's option
  `ruleNegativeMessage`.

checkRule
---------

`checkRule` is the macro which is runs to check the Nim code. It is split on
several parts. Each part must have at least `discard` statement. The
`checkRule` is a recursive statement, it executes itself from the main AST node
of the code to each its child. All the checking parts are:

* `initCheck` - the initialization of checking the Nim code with the rule. This
  part of code is run only once. It is a good place to initialize some global
  variables, etc.
* `startCheck` - the fragment which will be executed each time, before check any
  AST node of the Nim code.
* `checking` - the part in which the Nim code is checked. Executed for each AST
  node of the Nim code.
* `endCheck` - the part executed at the end of checking, same as `initCheck`,
  executed only once. It shows the rule's summary, etc.

`checkRule` has access to the following variables:

* `astNode` - the currently checked Nim code as AST node as pointer. While the
  pointer can't be changed, the node (and Nim code itself) can be modified.
* `parentNode` - the parent AST node of the currently checked Nim code. Same as
  `astNode`, the pointer can't be changed but the Nim code is modifable.
* `rule` - the rule data structure as an object. All its content can be
  modified. It contains fields:
  * `options` - the list of the rule options entered by the user in the
    configuration file. It is a sequence of strings.
  * `parent` - if true, the currently checked Nim code is the main AST node of
    the code to check. Boolean value.
  * `fileName` - the name of the file which contains the checked Nim code.
    String value.
  * `negation` - if true, the rule is configured as a negation (with word *not*
    in the configuration file). Boolean value.
  * `ruleType` - the type of the rule: `check`, `fix`, `search` or `count`.
    Enumeration.
  * `amount` - the amount of results found in the previous iterations of
    checking the Nim code. Integer value.
  * `enabled` - if true, the rule is enabled for the currently checked Nim
    code and the check is performed. Boolean value.
  * `fixCommand` - the command executed by `fix` type of the rule. Sets by the
    user in the configuration file. String value.
  * `identsCache` - the Nim idents cache needed for some internal rule code. It
    is recomended to not change it.
  * `forceFixCommand` - if true, the rule should use `fixCommand` for `fix`
    type of the rule instead of its own code. Sets by the user in the
    configuration file. Boolean value.
* `isParent` - if true, the rule is in the main AST node of the currently
  checked Nim code. Boolean, read only value.
* `messagePrefix` - the prefix added to each log's message. Its content depends
  on the level of the program's messages set in the configuration file. String,
  read only value.

`checkRule` can use the follwing procedures and templates:

* `message(text: string; returnValue: var int; level: Level = lvlError; decrease: bool = true)` - prints
  the selected `text` as the program's log's message and modify the rule
  results amount `rule.amount` via  `returnValue` parameter. If `decrease`
  parameter is set to true, the `returnValue` will be decreased, otherwise
  increased. `level` is the level of the log message.
* `errorMessage(text: string; e: ref Exception = nil): int` - prints the
  selected `text` as the program's error message. If parameter `e` isn't `nil`,
  it also shows the message and stack trace, in debug builds only, for the
  current exception.
* `setRuleState(node: PNode; ruleName: string; oldState: var bool)` - checks and
  sets the state, enabled or disabled, of the rule, based on the program's
  pragmas in the code. `node` is the AST node of the Nim code currently
  checked, `ruleName` is usually set to the configuration variable `ruleName`
  and `oldState` is the modified state of the rule, usually set to
  `rule.state`, it can be modified by `setRuleState` call.
* `setResult*(checkResult: bool; positiveMessage, negativeMessage: string; node: PNode; ruleData: string = ""; params: varargs[string])` - sets
  the result of checking the Nim code as the AST `node`. `checkResult` is the
  result of checking of the Nim code, for example, true if the code's
  documentation found or if procedure has the selected pragma. `positiveMessage`
  will be shown when `checkResult` fullfills the rule's settings, like
  negation, type, etc. `negativeMessage` will be shown when `checkResilt` not
  fullfils the rule's settings. Both usualy are set to the rule's configuration
  options like `positiveMessage` and `negativeMessage`. `ruleData` is an
  additional data used by `fix` type of the rule. `params` contains list of
  additional data, used in the program's messages, `positiveMessage` and
  `negativeMessage`. To use any of `params`, use template `{params[number]}`
  in messages, where **[number]** is the number of the param on the list,
  starting from zero.
* `getNodesToCheck(parentNode, node: PNode): PNode` - get the flattened into
  one list, the list of AST nodes, starting from currently checked `node` of
  the Nim code.

fixRule
-------

`fixRule` is the macro which will be executed for `fix` type of the rule. It
must contains at least `discard` statement. If it is set to `discard` only
statement, then the command set by the configuration `fixCommand` setting will
be executed. Otherwise the code inside the macro will be used, unless the
program's configuration option `forceFixCommand` is set. The macro returns
`true` if the Nim code was modified so the program can save the new version of
the Nim code to the file, otherwise `false`. If `fixCommand` executed, the
macro always returns `false`.


`fixRule` has access to the following variables:

* `astNode` - the currently checked Nim code as AST node as pointer. While the
  pointer can't be changed, the node (and Nim code itself) can be modified.
* `parentNode` - the parent AST node of the currently checked Nim code. Same as
  `astNode`, the pointer can't be changed but the Nim code is modifable.
* `rule` - the rule data structure as an object. It contains fields:
  * `options` - the list of the rule options entered by the user in the
    configuration file. It is a sequence of strings.
  * `parent` - if true, the currently checked Nim code is the main AST node of
    the code to check. Boolean value.
  * `fileName` - the name of the file which contains the checked Nim code.
    String value.
  * `negation` - if true, the rule is configured as a negation (with word *not*
    in the configuration file). Boolean value.
  * `ruleType` - the type of the rule: `check`, `fix`, `search` or `count`.
    Enumeration.
  * `amount` - the amount of results found in the previous iterations of
    checking the Nim code. Integer value.
  * `enabled` - if true, the rule is enabled for the currently checked Nim
    code and the check is performed. Boolean value.
  * `fixCommand` - the command executed by `fix` type of the rule. Sets by the
    user in the configuration file. String value.
  * `identsCache` - the Nim idents cache needed for some internal rule code. It
    is recomended to not change it.
  * `forceFixCommand` - if true, the rule should use `fixCommand` for `fix`
    type of the rule instead of its own code. Sets by the user in the
    configuration file. Boolean value.
* `data` - additional data sent to the `fixRule` macro, usualy via `setResult`
  call. String value.
