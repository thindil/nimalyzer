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
   file for it. Please check documentation for `configuration syntax <config.html>`_
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
   example: `{.ruleOff: "hasDoc".}`. Please refer to the rules' documentation to
   check where the pragma should be placed. Some rules allow it in any place in
   a code, others require it in the specific place. For example, rule *hasDoc*
   require that pragma in a declaration.

3. If you want to re-enable a rule in a code later, insert pragma ruleOn. For
   example: `{.ruleOn: "hasDoc".}`. Same as with disabling, please refer to the
   rules' documentation where to place the pragma. Usually, rules require it in
   the same location where pragma *ruleOff* should be placed.

Notes
-----

* Names of the rules used for pragmas are case-insensitive, thus "hasDoc" can
  be also "hasdoc", "HasDoc" or "HASDOC".
* Names of the rules used for pragmas are strings, compared to the value of
  `ruleName` constants defined in the rules.
* Disabling the rule in the code cause to disable all checks of that type in
  the code. For example if you used `{.ruleOff: hasEntity.}` and your
  configuration file contains several settings for that rule, all of them will
  be disabled from this point in the code.
