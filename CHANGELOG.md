# Changelog
All notable changes to this project will be documented in this file.

Tag **BREAKING** means the change break compatibility with a previous version
of the program.

## [Unreleased]

### Added
- Checking global variables declarations do they have documentation with
  `hasDoc` rule
- New type of rules: `fix`. For most of rules it just execute a configured
  command when a rule find a problem, but some rules can automatically fix
  the reported problem. Please refer to the program's documentation how the
  type of rules works.
- The option to enable checking public fields of types declarations for
  documentation for `hasDoc` rule.

### Changed
- Better checking for named parameters by `namedParams` rule
- Don't check for named parameters in *defined* procedure by `namedParams` rule
- Don't check for type or value for declarations which unpack tuples by
  `varDeclared` rule
- Updated the project's documentation
- **BREAKING**: rule `hasDoc` doesn't check public fields of objects types for
  documentation
- Updated contributing guide

### Fixed
- Typo in Changelog
- `hasDoc` rule doesn't detect if procedure doesn't have documentation if one
  of its child has it
- Message level for `hasEntity` rule when it doesn't find the selected entity
  with check type of the rule
- Message text for `hasEntity` rule when the program's verbosity is set to
  higher level than default
- Negation doesn't work for `paramsUsed` rule
- Detection of variables which can be updated to *let* or *const* with
  `varUplevel` rule
- Result of negative check for `varUplevel` rule

## [0.3.0] - 2023-04-28

### Added
- New rule `varUplevel` to check if declaration of variables can be updated to
  *let* or *const*.
- New rule `localHides` to check if local variables declarations hide global
  ones.
- New rule `namingConv` to check if variables, procedures and enumerations
  fields follow the selected naming convention.

### Changed
- Updated the project's documentation
- Updated README.md
- Disabling and enabling rules' pragmas can be now placed before or in the
  code fragment for which rules should be disabled or enabled.
- Better checking for parameters usage by `paramsUsed` rule

### Fixed
- Typos in Changelog
- `hasPragma` rule doesn't return error if a declaration doesn't have any
  pragmas
- `hasEntity` rule doesn't check properly for entities, regression
- `hasDoc` rule doesn't check properly if module has documentation
- `hadDoc` rule doesn't detect if template has documentation
- Detection of names of parameters of procedures in `paramsUsed` rule, when
  parameter has pragma
- Detection of values of variables' declarations in `varDeclared` rule

## [0.2.0] - 2023-03-20

### Added
- Ability to set parent entity and index of child for rule `hasEntity`
- Ability to disable and re-enable the program's rules with pragmas `ruleOn`
  and `ruleOff`
- Better reporting of the program's errors, especially when the program is
  built in debug mode
- New rule `varDeclared` to check if variables declared in a module have
  declared types or values
- **BREAKING**: Ability to set the type of declaration which will be checked
  for pragmas for rule `hasPragma`
- **BREAKING**: Ability to set the type of declaration which will be checked
  for the parameters' usage for rule `paramsUsed`

### Changed
- Updated the project's documentation
- Updated contributing guide

### Fixed
- Result for negative check for `hasDoc`, `hasEntity`, `namedParams` and
  `paramsUsed` rules
- Result for negative search for `hasEntiry` rule
- Show the name of the entity when search for entity with any name in
  `hasEntity` rule
- Detecting documentation of templates with `hasDoc` rule
- Return value for check type of rules when nothing was found in a code

## [0.1.0] - 2023-02-13
- Initial release
