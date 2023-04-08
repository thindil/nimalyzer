# Changelog
All notable changes to this project will be documented in this file.

Tag **BREAKING** means the change break compatibility with a previous version
of the program.

## [Unreleased]

### Changed
- Updated the project's documentation
- Updated README.md

### Fixed
- Typos in Changelog
- `hasPragma` rule doesn't return error if a declaration doesn't have any
  pragmas
- `hasEntity` rule doesn't check properly for entities, regression
- `hasDoc` rule doesn't check properly if module has documentation
- `hadDoc` rule doesn't detect if template has documentation
- Detection of names of parameters of procedures in `paramsUsed` rule, when
  parameter has pragma

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
