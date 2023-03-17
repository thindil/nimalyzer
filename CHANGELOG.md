# Changelog
All notable changes to this project will be documented in this file.

Tag **BREAKING** means the change break compatibility with a previous version
of the program.

## [Unreleased]

### Added
- Ability to set parent entity and index of child for rule hasEntity
- Ability to disable and reenable the program's rules with pragmas `ruleOn`
  and `ruleOff`
- Better reporting of the program's errors, especially when the program is
  built in debug mode
- New rule `varDeclared` to check if variables declared in a module have
  declared types or values
- **BREAKING**: Ability to set the type of declaration which will be checked
  for pragmas for rule `hasPragma`.
- **BREAKING**: Ability to set the type of declaration which will be checked
  for the paramters usage for rule `paramsUsed`.

### Changed
- Updated the project's documentation
- Updated contributing guide

### Fixed
- Result for negative check for hasDoc, hasEntity, namedParams and paramsUsed
  rules
- Result for negative search for hasEntiry rule
- Show the name of the entity when search for entity with any name in hasEntity
  rule

## [0.1.0] - 2023-02-13
- Initial release
