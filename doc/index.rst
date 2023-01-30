=======================
Nimalyzer documentation
=======================

General information
===================

Nimalyzer is a static code analyzer for [Nim](https://github.com/nim-lang/Nim)
programming language. It allows checking a Nim source code against predefined
rules. Its design is inspired by [AdaControl](https://www.adalog.fr/en/adacontrol.html).
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
   file for it. Please check documentation for [configuration syntax](config.html)
   and list of [available rules](available_rules.html) for more details. In your
   configuration file you have to set at least one source file to check and at
   least one rule to use.

2. Run Nimanalyzer with path to your configuration file as the argument. For example:
   `nimalyzer config/nimalyzer.cfg` and read its output.

