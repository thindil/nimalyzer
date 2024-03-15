# Changelog
All notable changes to this project will be documented in this file.

Tag **BREAKING** means the change break compatibility with a previous version
of the program.

## [Unreleased]

### Changed
- Using unittest2 package for the project's unit tests.
- **BREAKING**: adding or removing rules from the program doesn't need to
  update file *rulesList.txt*. Now it is just adding or removing the Nim file
  with the rule's code to *rules* directory.

### Fixed
- The rule `ifStatements` checks `when` statements for upgrade to `case`
  statements.
- Showing the explanation for negative checks of the `forStatements` rule.
- The result for negative `count` type check for `assignments` and
  `varuplevel` rules.
- The result for `count` type check for `casestatements`, `ifstatements` and
  `localhides` rules.
- Showing the detailed information about found result for `count` type of
  the program's rules.
- The summary information for negative `count` type check for `hasdoc`,
  `hasentity`, `haspragma` and `localhides` rules.
- The summary information for checks for `paramsused` and `vardeclared` rules.
- The result for `search` type check for `casestatements`, `ifstatements` and
  `forstatements` rules.
- The summary information for negative `search` type check for `hasdoc` rule.

## [0.7.1] - 2023-10-03

### Fixed
- Detecting a documentation of types by `hasDoc` rule if the type has defined
  a pragma(s).

## [0.7.0] - 2023-09-14

### Added
- The option to check only unborrowed procedures, functions and methods for
  pragmas with `hasPragma` rule.
- The configuration setting `ignore` for remove the selected file from the
  list of files to check.
- The rule's name to the program's rules' messages.

### Changed
- Updated the project's documentation.
- **BREAKING**: name of module required to import for use the program's pragmas
  in the checked code.
- Updated contributing guide.

### Fixed
- Don't install file *rulesList.txt*. It is needed only for compilation of the
  program.
- Checking usage of parameters of procedures by `paramsUsed` rule.
- Detecting a documentation of definition of procedures, functions, etc. with
  `hasDoc` rule.
- Crash when checking for named parameters in call by `namedParams` rule when
  there is more results than allowed.
- Crash when there is more results than set by the user in a configuration
  file.
- Detecting a documentation of types with `hasDoc` rule.
- Installing the program should also contains file *nimalyzer.nim* for ability
  to disable and enable rules.
- Detecting a documentation of variables in `let` section with `hasDoc` rule.
- Detecting calls by `namedParams` rule.
- Detecting empty `if` statements with `ifStatements` rule.
- Detecting empty `for` statements with `forStatements` rule.
- Don't check the last parameter of a call if it is a statements' list with
  `namedParams` rule.
- Crash when checking declarations of variables with `varDeclared` rule.
- Crash when checking variables with `localHides` rule.
- Checking declarations of multiple variables with `varDeclared` rule.

## [0.6.0] - 2023-08-18

### Added
- `fix` type of rule to `paramsUsed` rule. It now can remove unused parameters
  from procedures' declaration.
- **BREAKING**: rules `forStatements` and `ifStatements` need now option to set
  what kind of checks will be performed.
- Ability to check for empty `for` statements to `forStatements` rule.
- Coloring output of the program in console.
- Configuration setting `maxreports` to limit the amount of reported problems
  by the program.
- Ability to check the maximum and minimum amount of branches of `if`
  statements to `ifStatements` rule.
- **BREAKING**: checking for invalid the program's configuration's settings in
  a configuration files.
- Information about the line number to errors' messages during parsing the
  program's configuration files.
- Configuration setting `explanation` which allow adding message to the
  program's rules which shown when the checked code violates the rule's
  setting.
- New rule `caseStatements` to check `case` statements in a code for minimum
  and maximum amount of their branches.
- New rule `comments` to check the comments in a code with the selected regular
  expression or do a code contains a legal header.
- New rule `assignments` to check the assignments in a code do they are
  shorthand assignments or not.
- New rule `complexity` to check code blocks in a code for their cyclomatic
  complexity.

### Changed
- Made the program's configuration files syntax case-insensitive.
- Updated README.md.

### Fixed
- Typos in the program's documentation.
- Checking usage of parameters in declarations by `paramsUsed` rule.
- Typos in the program's messages.

## [0.5.0] - 2023-07-10

### Added
- Configuration setting `reset` which allows reset the program's configuration
  in the configuration file to change the program's settings without stopping
  it.
- Configuration setting `message` to add a custom messages to the program's
  output, console and the log file.
- Configuration setting `forcefixcommand` which allows force subsequent
  program's rules to use their auto fix code or the command defined with the
  `fixcommand` setting.
- **BREAKING**: rule `hasDoc` needs now option to set what kind of entities
  should be checked.
- `fix` type of rule to `hasDoc` rule. It can now delete documentation or
  add a template of documentation to the checked code.
- New rule `ifStatements` to check `if` statements in code for various things,
  like empty statements, negative conditions, etc.
- New rule `forStatements` to check `for` statements in code do they use `pairs`
  and `items` iterators or not.

### Changed
- Updated the project's documentation.
- Made rules' custom options case-insensitive.
- Better formatting of error message for rules.

### Fixed
- Typos in Changelog.
- Typos in the program's configuration's documentation.
- Detecting documentation of objects types declaration by `hasDoc` rule.

## [0.4.0] - 2023-06-08

### Added
- Checking global variables declarations do they have documentation with
  `hasDoc` rule.
- New type of rules: `fix`. For most rules, it just executes a configured
  command when a rule finds a problem, but some rules can automatically fix
  the reported problem. Please refer to the program's documentation how the
  type of rules works.
- The option to enable checking public fields of types declarations for
  documentation for `hasDoc` rule.
- Ability to check usage of parameters in macros only for `paramsUsed` rule.

### Changed
- Better checking for named parameters by `namedParams` rule.
- Don't check for named parameters in *defined* procedure by `namedParams` rule.
- Don't check for type or value for declarations which unpack tuples by
  `varDeclared` rule.
- Updated the project's documentation.
- **BREAKING**: rule `hasDoc` doesn't check public fields of objects types for
  documentation.
- Updated contributing guide.

### Fixed
- Typos in Changelog.
- `hasDoc` rule doesn't detect if procedure doesn't have documentation if one
  of its child has it.
- Message level for `hasEntity` rule when it doesn't find the selected entity
  with check type of the rule.
- Message text for `hasEntity` rule when the program's verbosity is set to
  higher level than default.
- Negation doesn't work for `paramsUsed` rule.
- Detection of variables which can be updated to *let* or *const* with
  `varUplevel` rule.
- Result of negative check for `varUplevel` rule.

## [0.3.0] - 2023-04-28

### Added
- New rule `varUplevel` to check if declaration of variables can be updated to
  *let* or *const*.
- New rule `localHides` to check if local variables declarations hide global
  ones.
- New rule `namingConv` to check if variables, procedures and enumerations
  fields follow the selected naming convention.

### Changed
- Updated the project's documentation.
- Updated README.md.
- Disabling and enabling rules' pragmas can be now placed before or in the
  code fragment for which rules should be disabled or enabled.
- Better checking for parameters usage by `paramsUsed` rule.

### Fixed
- Typos in Changelog.
- `hasPragma` rule doesn't return error if a declaration doesn't have any
  pragmas.
- `hasEntity` rule doesn't check properly for entities, regression.
- `hasDoc` rule doesn't check properly if module has documentation.
- `hadDoc` rule doesn't detect if template has documentation.
- Detection of names of parameters of procedures in `paramsUsed` rule, when
  parameter has pragma.
- Detection of values of variables' declarations in `varDeclared` rule.

## [0.2.0] - 2023-03-20

### Added
- Ability to set parent entity and index of child for rule `hasEntity`.
- Ability to disable and re-enable the program's rules with pragmas `ruleOn`
  and `ruleOff`.
- Better reporting of the program's errors, especially when the program is
  built in debug mode.
- New rule `varDeclared` to check if variables declared in a module have
  declared types or values.
- **BREAKING**: Ability to set the type of declaration which will be checked
  for pragmas for rule `hasPragma`.
- **BREAKING**: Ability to set the type of declaration which will be checked
  for the parameters' usage for rule `paramsUsed`.

### Changed
- Updated the project's documentation.
- Updated contributing guide.

### Fixed
- Result for negative check for `hasDoc`, `hasEntity`, `namedParams` and
  `paramsUsed` rules.
- Result for negative search for `hasEntiry` rule.
- Show the name of the entity when search for entity with any name in
  `hasEntity` rule.
- Detecting documentation of templates with `hasDoc` rule.
- Return value for check type of rules when nothing was found in a code.

## [0.1.0] - 2023-02-13
- Initial release.
