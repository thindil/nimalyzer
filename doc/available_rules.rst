===============
Available rules
===============

.. default-role:: code
.. contents::

Hasdoc rule
===========
The rule to check if all public declarations (variables, procedures, etc)
have documentation comments
The syntax in a configuration file is::

  [ruleType] ?not? hasDoc

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search* and *count*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a public declaration which doesn't have documentation.
  Search type will list all public declarations which have documentation and
  raise error if nothing was found. Count type will simply list the amount
  of public declarations which have documentation.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about public declaration which have documentation.
  Probably useable only with search and count type of rule.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "hasDoc"* in the element from which the rule
should be disabled. For example, if the rule should be disabled for procedure
`proc main()`, the full declaration of it should be::

    proc main () {.ruleOff: "hasDoc".}

To enable the rule again, the pragma *ruleOn: "hasDoc"* should be added in
the element which should be checked. For example, if the rule should be
re-enabled for `const a = 1`, the full declaration should be::

    const a = 1 {.ruleOn: "hasDoc".}

Examples
--------

1. Check if all public declarations in module have documentation::

    check hasDoc

2. Search for all public declarations which don't have documentation::

    search not hasDoc

Hasentity rule
==============
The rule to check if the selected module has the selected entities, like
procedures, constants, etc. with the selected names. The syntax in a
configuration file is::

  [ruleType] ?not? hasentity [entityType] [entityName] ?parentEntity? ?childIndex?

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search* and *count*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if the selected type of entity with the selected name was not
  found in the module. Search type will list all entities of the selected
  type with the selected name and raise error if nothing was found. Count
  type will simply list the amount of the selected entities.
* optional word *not* means negation for the rule. For example, if rule is
  set to check for procedures named myProc, adding word *not* will change
  to inform only about modules without the procedure with that name.
* hasentity is the name of the rule. It is case-insensitive, thus it can be
  set as *hasentity*, *hasEntity* or *hAsEnTiTy*.
* entityType is the type of entity which will be looking for. Proper values
  are types used by Nim compiler, defined in file compiler/ast.nim in
  enumeration *TNodeKind*. Examples: *nkType*, *nkCall*.
* entityName is the name of entity which will be looking for. The rule
  search for the selected entity type, which name starts with entityName.
  For example, if entityType is set to nkProcDef and entityName is set to
  *myProc* the rule will find procedures named *myProc*, but also *myProcedure*.
* if optional parameter *parentEntity* is set then the entity will be searched
  only as a child of the selected type of entities. For example setting
  entityType to nkProcDef, entityName to myProc and parentEntity to nkStmtList
  will find all nested procedures with name *myProc* or *myProcedure*.
* if optional parameter *childIndex* is set, then the entity will be searched
  only as the selected child of the selected parent. In order for
  `*childIndex` parameter to work, the parameter *parentEntity* must be set
  too. If the value of the *childIndex* is a natural number, it is the index of
  the child counted from the beginning of the list of children. If the value is
  negative, it is the index of the child counted from the end of the list of
  children.

To look only for global entities, add `*` to the end of the entityName
parameter. Setting it to *MyProc\** will look only for global entities
which full name is MyProc.

Note
----

hasEntity rule is considered as a low level rule. It requires a
knowledge about Nim compiler, especially names of the Nim code nodes and the
generated source code tree to use. It is recommended to use other rules
instead of this one.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "hasEntity"* before the code's fragment which
shouldn't be checked.

To enable the rule again, the pragma *ruleOn: "hasEntity"* should be added
before the code which should be checked.

Examples
--------

1. Check if module has declared global procedure with name *myProc*::

    check hasEntity nkProcDef myProc*

2. Search for all defined global constants::

    search hasEntity nkConstSection *

3. Count the amount of global enumerations::

    count hasEntiry nkEnumTy *

4. Check if there are no declarations of global range types::

    check not hasEntity nkRange *

Haspragma rule
==============
The rule to check if the selected procedure has the selected pragma. The
syntax in a configuration file is::

  [ruleType] ?not? haspragma [listOfPragmas]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search* and *count*. For more information about the types of
  rules, please refer to the program's documentation. Check rule will
  looking for procedures with declaration of the selected list of pragmas
  and list all of them which doesn't have them, raising error either. Search
  rule will look for the procedures with the selected pragmas and list
  all of them which have the selected pragmas, raising error if nothing is
  found.  Count type will simply list the amount of the procedures with the
  selected pragmas.
* optional word *not* means negation for the rule. For example, if rule is
  set to check for pragma SideEffect, adding word *not* will change
  to inform only about procedures with that pragma.
* haspragma is the name of the rule. It is case-insensitive, thus it can be
  set as *haspragma*, *hasPragma* or *hAsPrAgMa*.
* listOfPragmas is the list of pragmas for which the rule will be looking
  for. Each pragma must be separated with whitespace, like::

    SideEffect gcSafe

It is possible to use shell's like globing in setting the names of the
pragmas. If the sign `*` is at the start of the pragma name, it means to
look for procedures which have pragmas ending with that string. For example,
`*Effect` will find procedures with pragma *SideEffect* but not
*sideeffect* or *effectPragma*. If sign `*` is at the end of the pragma
name, it means to look for procedures which have pragmas starting
with that string. For example, `raises: [*` will find procedures with
pragma *raises: []* or *raises: [Exception]* but not `myCustomraises: [custom]`.
If the name of the pragma starts and ends with sign `*`, it means to look
for procedures which have pragmas containing the string. For example, `*Exception*`
will find `raises: [MyException]` or `myCustomExceptionRaise`.

The list of pragmas must be in the form of console line arguments:

1. Each pragma name must be separated with whitespace: `myPragma otherPragma`
2. If the search string contains whitespace, it must be enclosed in quotes
   or escaped, like in the console line arguments: `"mypragma: [" otherPragma`
3. All other special characters must be escaped as in a console line
   arguments: `stringWith\"QuoteSign`

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "hasPragma"* in the element from which the rule
should be disabled. For example, if the rule should be disabled for procedure
`main()`, the full declaration of it should be::

     proc main() {.ruleOff: "hasPragma".}

To enable the rule again, the pragma *ruleOn: "hasPragma"* should be added in
the element which should be checked. For example, if the rule should be
re-enabled for `const a = 1`, the full declaration should be::

     const a = 1 {.ruleOn: "hasPragma".}

Examples
--------

1. Check if all procedures have declared pragma raises. It can be empty or
   contains names of raised exception::

     check hasPragma "raises: [*"

2. Find all procedures with have *sideEffect* pragma declared::

     search hasPragma sideEffect

3. Count amount of procedures which don't have declared pragma *gcSafe*::

     count not hasPragma gcSafe

4. Check if all procedures have declared pragmas *contractual* and *lock*.
   The *lock* pragma must have entered the level of the lock::

     check hasPragma contractual "lock: *"

Namedparams rule
================
The rule to check if all calls in the code uses named parameters
The syntax in a configuration file is::

  [ruleType] ?not? namedParams

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search* and *count*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a call which doesn't have all parameters named.
  Search type will list all calls which set all their parameters as named
  and raise error if nothing was found. Count type will simply list the
  amount of calls which set all their parameters as named.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about calls which have some parameters not named.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "namedParams"* before the code's fragment which
shouldn't be checked.

To enable the rule again, the pragma *ruleOn: "namedParams"* should be added
before the code which should be checked.

Examples
--------

1. Check if all calls in module set their parameters as named::

    check namedParams

2. Search for all calls which don't set their parameters as named::

    search not namedParams

Paramsused rule
===============
The rule to check if the selected procedure uses all its parameter
The syntax in a configuration file is::

  [ruleType] ?not? paramsUsed

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search* and *count*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a procedure which doesn't use all its parameters.
  Search type will list all procedures which uses their all parameters and
  raise error if nothing was found. Count type will simply list the amount
  of procedures which uses all their parameters.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about procedures which have all parameters used.
  Probably useable only with search and count type of rule.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "paramsUsed"* in the declaration from which the rule
should be disabled. For example, if the rule should be disabled for procedure
`main()`, the full declaration of it should be::

     proc main() {.ruleOff: "paramsUsed".}

To enable the rule again, the pragma *ruleOn: "paramsUsed"* should be added in
the element which should be checked. For example, if the rule should be
re-enabled for function `myFunc(a: int)`, the full declaration should be::

     func myFunc(a: int) {.ruleOn: "paramsUsed".}

Examples
--------

1. Check if all procedures in module uses their parameters::

    check paramsUsed

2. Search for all procedures which don't use their all parameters::

    search not paramsUsed

Vardeclared rule
================
The rule to check if the selected variable declaration (var, let and const)
has declared type and or value
The syntax in a configuration file is::

  [ruleType] ?not? varDeclared [declarationType]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search* and *count*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a declaration isn't in desired pattern. Search type
  will list all declarations with desired pattern and raise error if
  nothing was found. Count type will simply list the amount of declarations
  with the desired pattern.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about procedures without desired pattern.
  Probably useable only with search and count type of rule.
* declarationType is the desired type of variable's declaration to check.
  Possible values are: full - the declaration must have declared type and
  value for the variable, type - the declaration must have declared type for
  the variable, value - the declaration must have declared value for the
  variable.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "varDeclared"* in the declaration from which the rule
should be disabled. For example, if the rule should be disabled for variable
`var a: int`, the full declaration of it should be::

     var a: int {.ruleOff: "varDeclared".}

To enable the rule again, the pragma *ruleOn: "varDeclared"* should be added in
the element which should be checked. For example, if the rule should be
re-enabled for variable `let b = 2`, the full declaration should be::

     let b = 2 {.ruleOn: "varDeclared".}

Examples
--------

1. Check if all declarations have set type and value for them::

    check varDeclared full

2. Search for all declarations which don't set type for them::

    search not varDeclared type
