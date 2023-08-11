===============
Available rules
===============

.. default-role:: code
.. contents::

Assignments rule
================
The rule to check do assignments in the code follow some design patterns.
Checked things:

* Do assignment is or not a shorthand assignment

The syntax in a configuration file is::

  [ruleType] ?not? assignments [checkType]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is an assignment which violates any of the checks. Search
  type will list all assignments which violates any of checks or raise an
  error if nothing found. Count type will simply list the amount of the
  assignments which violates the checks. Fix type will try to upgrade the
  assignment to meet the rule settings. For example, it will ugprade the
  assignment to a shorthand assignment or replace by full if negation was
  used.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about assignments which not violate the checks. For
  example, it will raise an error when check type find a shorthand assignment.
* assignments is the name of the rule. It is case-insensitive, thus it can be
  set as *assignments*, *assignments* or *aSsIgNmEnTs*.
* checkType is the type of checks to perform on the assignments. Proper
  value is: *shorthand*. It will check if all assignments are shorthand
  assignments.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "assignments"* in the element in code before it.
For example, if the rule should be disabled for assignment `i = i + 1`, the
full declaration of it should be::

    {.ruleOff: "assignments".}
    i = i + 1

To enable the rule again, the pragma *ruleOn: "assignments"* should be added in
the code before it. For example, if the rule should be re-enabled for ` a += 1`,
the full declaration should be::

    {.ruleOn: "assignments".}
    a += 1

Examples
--------

1. Check if all assignments in the code are shorthand assignments::

    check assignments shorthand

2. Replace all shorthand assignments in the code with full assignments::

    fix not assignments shorthand

Casestatements rule
===================
The rule to check do `case` statements in the code don't contain some
expressions. Checked things:

* The maximum and minimum amount of `case` statements' branches.

The syntax in a configuration file is::

  [ruleType] ?not? caseStatements [checkType] [amount]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a `case` statement which violates any of the checks. Search
  type will list all statements which violates any of checks or raise an
  error if nothing found. Count type will simply list the amount of the
  statements which violates the checks. Fix type will execute the default
  shell command set by the program's setting **fixCommand**.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about the `case` statements which not violate the checks.
  Probably useable only with search and count type of rule.
* caseStatements is the name of the rule. It is case-insensitive, thus it can be
  set as *casestatements*, *caseStatements* or *cAsEsTaTeMeNtS*.
* checkType is the type of checks to perform on the `case` statements. Proper
  values are: *min* and *max*. Setting it min will check if all `case`
  statements have at least the selected amount of branches. Max value will
  check if the `case` statements have maximum the selected amount of branches.
* amount parameter is required for both types of checks. It is desired amount
  of branches for the `case` statements, minimal or maximum, depends on
  check's type.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "caseStatements"* in the code before it. For example,
if the rule should be disabled for the statement, the full declaration of it
should be::

    {.ruleOff: "caseStatements".}
    case a
    of 1:
      echo a

To enable the rule again, the pragma *ruleOn: "caseStatements"* should be added
in the code before it. For example, if the rule should be re-enabled for the
statement, the full declaration should be::

    {.ruleOn: "caseStatements".}
    case a
    of 1:
      echo a

Examples
--------

1. Check if all `case` statements have at least 4 branches::

    check caseStatements min 4

Comments rule
=============
The rule to check if the selected file contains a comment with the selected
pattern or a legal header. In the second option, it looks for word *copyright*
in the first 5 lines of the file. The rule works differently than other rules,
because it doesn't use AST representation of the checked code but operates
directly on the file which contains the code.
The syntax in a configuration file is::

  [ruleType] ?not? comments [checkType] [patternOrFileName]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a comment with the selected pattern (if pattern is
  checked) or there is no legal header in the code. Search type will list
  all comments which violates any of checks or raise an error if nothing
  found. Count type will simply list the amount of the comments which
  violates the checks. Fix remove the comment with the selected pattern
  from the code or add the selected legal header from file. In any other
  setting, the fix type will execute the default shell command set by the
  program's setting **fixCommand**.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about the comments which not violate the check.
* comments is the name of the rule. It is case-insensitive, thus it can be
  set as *comments*, *comments* or *--cOmMeNtS--*.
* checkType is the type of check to perform on the code's comments. Proper
  values are: *pattern* and *legal*. Pattern will check all the comments in
  the code against regular expression. Legal will check if the source code
  file contains legal information header.
* patternOrFileName parameter depends on the type of check. For *pattern*
  type it is a regular expression against which the comments will be checked.
  For *legal* type, it is the path to the file which contains the legal
  header, which will be inserted into code. Thus, in that situation, the
  parameter is required only for *fix* type of the rule. The file containing
  the legal header should contain only text of the header without comment marks.
  They will be added automatically by the rule.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "comments"* in the element from which the rule
should be disabled or in code before it. For example, if the rule should
be disabled for procedure `proc main()`, the full declaration of it should
be::

    proc main () {.ruleOff: "comments".}

To enable the rule again, the pragma *ruleOn: "comments"* should be added in
the element which should be checked or in code before it. For example, if
the rule should be re-enabled for `const a = 1`, the full declaration should
be::

    const a {.ruleOn: "comments".} = 1

Examples
--------

1. Check if there is a comment which starts with FIXME word::

   check comments pattern ^FIXME

2. Add a legal header from file legal.txt::

   fix comments legal legal.txt

Forstatements rule
==================
The rule to check do `for` statements in the code contains or not some
expressions. Checked things:

* Empty statements. `For` statements, which contains only `discard` statement.
* Do `for` statements explicitly calls iterators `pairs` or `items`.

The syntax in a configuration file is::

  [ruleType] ?not? forStatements [checkType]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a `for` statement which violates the check. Search
  type will list all statements which violates the check or raise an
  error if nothing found. Count type will simply list the amount of the
  statements which violates the check. Fix type will try to fix the code
  which violates check. The negation of fix type doesn't work with checkType
  set to "empty".
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about the `for` statements which not violates the
  rule's check.
* forStatements is the name of the rule. It is case-insensitive, thus it can be
  set as *forstatements*, *forStatements* or *fOrStAtEmEnTs*.
* checkType is the type of checks to perform on the `for` statements. Proper
  values are: *all*, *iterators*, *empty*. Setting it to all will perform
  all rule's checks on statements. Iterators value will check only if the
  `for` statements use `pairs` and `items` iterators. Empty value will check
  if the `for` statements doesn't contain only a `discard` statement.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "forStatements"* in the code before it. For
example, if the rule should be disabled for the selected statement, the full
declaration of it should be::

    {.ruleOff: "forStatements".}
    for i in 1 .. 5:
      echo i

To enable the rule again, the pragma *ruleOn: "forStatements"* should be
added in the code before it. For example, if the rule should be re-enabled
for the statement, the full declaration should be::

    {.ruleOn: "forStatements".}
    for i in 1 .. 5:
      echo i

Examples
--------

1. Check if all `for` statements have direct calls for iterators::

    check forStatements iterators

2. Remove all empty `for` statements::

    fix not forStatements empty

Hasdoc rule
===========
The rule to check if all public declarations (variables, procedures, etc)
have documentation comments. It doesn't check public fields of types
declarations for the documentation.
The syntax in a configuration file is::

  [ruleType] ?not? hasDoc [entityType] [templateFile]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a public declaration which doesn't have documentation.
  Search type will list all public declarations which have documentation and
  raise error if nothing was found. Count type will simply list the amount
  of public declarations which have documentation. Fix type with negation
  will remove all documentation from the selected type of the code entities.
  Without negation, it will add a template of documentation from the selected
  text file into the configured type of code entities.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about public declaration which have documentation.
  Probably useable only with search and count type of rule.
* hasDoc is the name of the rule. It is case-insensitive, thus it can be
  set as *hasdoc*, *hasDoc* or *hAsDoC*.
* entityType is the type of entity which will be looking for. Proper values
  are: `all`: check everything what can have documentation but without fields
  of objects' declarations, `callables`: check all declarations of
  subprograms (procedures, functions, macros, etc.), `types`: check declarations
  of types, `typesFields`: check declarations of objects' fields, `modules`:
  check only module for documentation.
* templateFile is parameter required only by *fix* type of hasDoc rule.
  Other types of the rule can skip setting it. It should contain the template
  of documentation which will be inserted into the checked code. The
  documentation should be in reStructuredText format without leading sign
  for Nim documentation. It will be inserted in all desired types of entities.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "hasDoc"* in the element from which the rule
should be disabled or in code before it. For example, if the rule should be
disabled for procedure `proc main()`, the full declaration of it should be::

    proc main () {.ruleOff: "hasDoc".}

To enable the rule again, the pragma *ruleOn: "hasDoc"* should be added in
the element which should be checked or in code before it. For example, if
the rule should be re-enabled for `const a = 1`, the full declaration should
be::

    const a {.ruleOn: "hasDoc".} = 1

Examples
--------

1. Check if all public declarations in module have documentation::

    check hasDoc all

2. Search for all modules which don't have documentation::

    search not hasDoc modules

Hasentity rule
==============
The rule to check if the selected module has the selected entities, like
procedures, constants, etc. with the selected names. The syntax in a
configuration file is::

  [ruleType] ?not? hasentity [entityType] [entityName] ?parentEntity? ?childIndex?

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*,  *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if the selected type of entity with the selected name was not
  found in the module. Search type will list all entities of the selected
  type with the selected name and raise error if nothing was found. Count
  type will simply list the amount of the selected entities. Fix type will
  execute the default shell command set by the program's setting
  **fixCommand**.
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

  [ruleType] ?not? haspragma [entityType] [listOfPragmas]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check rule will
  looking for procedures with declaration of the selected list of pragmas
  and list all of them which doesn't have them, raising error either. Search
  rule will look for the procedures with the selected pragmas and list
  all of them which have the selected pragmas, raising error if nothing is
  found.  Count type will simply list the amount of the procedures with the
  selected pragmas. Fix type will try to append or remove the pragmas from
  the list to procedures. Please read general information about the fix type
  of rules about potential issues.
* optional word *not* means negation for the rule. For example, if rule is
  set to check for pragma SideEffect, adding word *not* will change
  to inform only about procedures with that pragma.
* haspragma is the name of the rule. It is case-insensitive, thus it can be
  set as *haspragma*, *hasPragma* or *hAsPrAgMa*.
* entityType is the type of code's entity which will be checked for the
  selected pragmas. Possible values: `procedures`: check all procedures,
  functions and methods. `templates`: check templates only. `all`: check
  all routines declarations (procedures, functions, templates, macros, etc.).
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
should be disabled or in code before it. For example, if the rule should be
disabled for procedure `main()`, the full declaration of it should be::

     proc main() {.ruleOff: "hasPragma".}

To enable the rule again, the pragma *ruleOn: "hasPragma"* should be added in
the element which should be checked or in code before it. For example, if
the rule should be re-enabled for `const a = 1`, the full declaration should
be::

     const a {.ruleOn: "hasPragma".} = 1

Examples
--------

1. Check if all procedures have declared pragma raises. It can be empty or
   contains names of raised exception::

     check hasPragma procedures "raises: [*"

2. Find all declarations with have *sideEffect* pragma declared::

     search hasPragma all sideEffect

3. Count amount of procedures which don't have declared pragma *gcSafe*::

     count not hasPragma procedures gcSafe

4. Check if all procedures have declared pragmas *contractual* and *lock*.
   The *lock* pragma must have entered the level of the lock::

     check hasPragma procedures contractual "lock: *"

Ifstatements rule
=================
The rule to check do `if` statements in the code don't contain some
expressions. Checked things:

* Empty statements. `If` statements, which contains only `discard` statement.
* A branch `else` after a finishing statement like `return`, `continue`,
  `break` or `raise`. Example::

    if a == 1:
      return
    else:
      doSomething()

* A negative condition in `if` statements with a branch `else`. Example::

    if a != 1:
      doSomething()
    else:
      doSomething2()

* The maximum and minimum amount of `if` statements' branches. The check
  must be set explicitly, it isn't performed when option *all* is set.

The syntax in a configuration file is::

  [ruleType] ?not? ifStatements [checkType] [amount]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a `if` statement which violates any of the checks. Search
  type will list all statements which violates any of checks or raise an
  error if nothing found. Count type will simply list the amount of the
  statements which violates the checks. Fix type will try to fix the code
  which violates checks: will remove empty statements, move outside the `if`
  block code after finishing statement or replace negative condition in the
  statement with positive and move the code blocks. Fix type not works with
  negation.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about the `if` statements which not violate the checks.
  Probably useable only with search and count type of rule.
* ifStatements is the name of the rule. It is case-insensitive, thus it can be
  set as *ifstatements*, *ifstatements* or *iFsTaTeMeNts*.
* checkType is the type of checks to perform on the `if` statements. Proper
  values are: *all*, *negative*, *moveable*, *empty*, *min* and *max*.
  Setting it to all will perform all rule's checks on statements except for
  the check for maximum and minimum amount of branches. Negative value will
  check only if the `if` statements don't have a negative condition with branch
  `else`. Moveable value will check only if the content of `else` branch can
  be moved outside the statement. Empty value will check if the `if`
  statements doesn't contain only a `discard` statement. Min value will check
  if all `if` statements have at least the selected amount of branches. Max
  value will check if the `if` statements have maximum the selected amount of
  branches.
* amount parameter is required only for *min* and *max* types of checks and
  it is ignored for another. It is desired amount of branches for the `if`
  statements, minimal or maximum, depends on check's type.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "ifStatements"* in the code before it. For example,
if the rule should be disabled for the statement, the full declaration of it
should be::

    {.ruleOff: "ifStatements".}
    if a == 1:
      echo a

To enable the rule again, the pragma *ruleOn: "ifStatements"* should be added
in the code before it. For example, if the rule should be re-enabled for the
statement, the full declaration should be::

    {.ruleOn: "ifStatements".}
    if a == 1:
      echo a

Examples
--------

1. Check if all `if` statements are correct::

    check ifStatements all

2. Remove all empty `if` statements::

    fix ifStatements empty

3. Check if all `if` statements have at least 3 branches:

    check ifStatements min 3

Localhides rule
===============
The rule check if the local declarations in the module don't hide (have the
same name) as a parent declarations declared in the module.
The syntax in a configuration file is::

  [ruleType] ?not? localHides

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check rule will
  raise an error if it finds a local declaration which has the same name as
  one of parent declarations, search rule will list any local declarations
  with the same name as previously declared parent and raise an error if
  nothing found. Count rule will simply list the amount of local
  declarations which have the same name as parent ones. Fix type will try
  to append a prefix `local` to the names of the local variables which
  hide the variable. It doesn't anything for rules with negation. Please
  read general information about the fix type of rules about potential
  issues.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about local declarations which don't have name as
  previously declared parent ones. Probably useable only for count type of
  rule. Search type with negation will return error as the last declaration
  is always not hidden.
* localHides is the name of the rule. It is case-insensitive, thus it can be
  set as *localhides*, *localHides* or *lOcAlHiDeS*.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "localHides"* in the element from which the rule
should be disabled or in code before it. For example, if the rule should
be disabled for procedure `proc main()`, the full declaration of it should
be::

    proc main () {.ruleOff: "localHides".}

To enable the rule again, the pragma *ruleOn: "localHides"* should be added in
the element which should be checked or in code before it. For example, if
the rule should be re-enabled for `const a = 1`, the full declaration should
be::

    const a {.ruleOn: "localHides".} = 1

Examples
--------

1. Check if any local declaration hides the parent ones::

    check localHides

2. Search for all local declarations which not hide the parent ones::

    search not localHides

Namedparams rule
================
The rule to check if all calls in the code uses named parameters
The syntax in a configuration file is::

  [ruleType] ?not? namedParams

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a call which doesn't have all parameters named.
  Search type will list all calls which set all their parameters as named
  and raise error if nothing was found. Count type will simply list the
  amount of calls which set all their parameters as named. Fix type will
  execute the default shell command set by the program's setting
  **fixCommand**.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about calls which have some parameters not named.
* namedParams is the name of the rule. It is case-insensitive, thus it can be
  set as *namedparams*, *namedParams* or *nAmEdPaRaMs*.

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

Namingconv rule
===============
The rule check if the selected type of entries follow the selected naming
convention. It can check variables, procedures and enumerations' values.
The syntax in a configuration file is::

  [ruleType] ?not? namingConv [entityType] [nameExpression]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a selected entity type which doesn't follow the
  selected naming convention. Search type will list all entities of the
  selected type which follows the selected naming convention. Count type
  will simply list the amount of the selected type of entities, which follows
  the naming convention. Fix type will execute the default shell command set
  by the program's setting **fixCommand**.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about the selected type of entities, which doesn't
  follow the selected naming convention for search and count types of rules
  and raise error if the entity follows the naming convention for check type
  of the rule.
* namingConv is the name of the rule. It is case-insensitive, thus it can be
  set as *namingconv*, *namingConv* or *nAmInGcOnV*.
* entityType is the type of code's entities to check. Possible values are:
  variables - check the declarations of variables, enumerations - check the
  names of enumerations values and procedures - check the names of the
  declarations of procedures.
* nameExpression - the regular expression which the names of the selected
  entities should follow. Any expression supported by PCRE is allowed.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "namingConv"* in the element from which the rule
should be disabled or in code before it. For example, if the rule should
be disabled for procedure `proc main()`, the full declaration of it should
be::

    proc main () {.ruleOff: "namingConv".}

To enable the rule again, the pragma *ruleOn: "namingConv"* should be added in
the element which should be checked or in code before it. For example, if
the rule should be re-enabled for `const a = 1`, the full declaration should
be::

    const a {.ruleOn: "namingConv".} = 1

Examples
--------

1. Check if names of variables follow standard Nim convention::

    check namingConv variables [a-z][A-Z0-9_]*

2. Find procedures which names ends with *proc*::

    search namingConv procedures proc$

3. Count enumerations which values are not start with *enum*::

    count not namingConv enumerations ^enum

Paramsused rule
===============
The rule to check if the selected procedure uses all its parameter
The syntax in a configuration file is::

  [ruleType] ?not? paramsUsed [declarationType]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a procedure which doesn't use all its parameters.
  Search type will list all procedures which uses their all parameters and
  raise error if nothing was found. Count type will simply list the amount
  of procedures which uses all their parameters. Fix type will remove the
  unused parameter from the procedure's declaration. It will also stop
  checking after remove. The fix type of the rule does nothing with negation.
  Please read general information about the fix type of rules about potential
  issues.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about procedures which have all parameters used.
  Probably useable only with search and count type of rule.
* paramsUsed is the name of the rule. It is case-insensitive, thus it can be
  set as *paramsUsed*, *paramsUsed* or *pArAmSuSeD*.
* declarationType is the type of declaration which will be checked for the
  parameters usage. Possible values: `procedures`: check all procedures,
  functions and methods. `templates`: check templates only. `macros`: check
  macros only. `all`: check all routines declarations (procedures,
  functions, templates, macros, etc.).

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "paramsUsed"* in the declaration from which the rule
should be disabled or in code before it. For example, if the rule should be
disabled for procedure `main()`, the full declaration of it should be::

     proc main() {.ruleOff: "paramsUsed".}

To enable the rule again, the pragma *ruleOn: "paramsUsed"* should be added in
the element which should be checked or in code before it. For example, if
the rule should be re-enabled for function `myFunc(a: int)`, the full
declaration should be::

     func myFunc(a: int) {.ruleOn: "paramsUsed".}

Examples
--------

1. Check if all procedures in module uses their parameters::

    check paramsUsed procedures

2. Search for all declarations which don't use their all parameters::

    search not paramsUsed all

Vardeclared rule
================
The rule to check if the selected variable declaration (var, let and const)
has declared type and or value
The syntax in a configuration file is::

  [ruleType] ?not? varDeclared [declarationType]

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  an error if there is a declaration isn't in desired pattern. Search type
  will list all declarations with desired pattern and raise error if
  nothing was found. Count type will simply list the amount of declarations
  with the desired pattern. Fix type will execute the default shell command
  set by the program's setting **fixCommand**.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about procedures without desired pattern.
  Probably useable only with search and count type of rule.
* varDeclared is the name of the rule. It is case-insensitive, thus it can be
  set as *vardeclared*, *varDeclared* or *vArDeClArEd*.
* declarationType is the desired type of variable's declaration to check.
  Possible values are: full - the declaration must have declared type and
  value for the variable, type - the declaration must have declared type for
  the variable, value - the declaration must have declared value for the
  variable.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "varDeclared"* before the block of code from which
the rule should be disabled. For example, if the rule should be disabled for
variable## `var a: int`, the full declaration of it should be::

     {.ruleOff: "varDeclared".}
     var a: int

To enable the rule again, the pragma *ruleOn: "varDeclared"* should be added
before the declaration which should be checked. For example, if the rule
should be re-enabled for variable `let b = 2`, the full declaration should
be::

     {.ruleOn: "varDeclared".}
     let b = 2

Examples
--------

1. Check if all declarations have set type and value for them::

    check varDeclared full

2. Search for all declarations which don't set type for them::

    search not varDeclared type

Varuplevel rule
===============
The rule checks if declarations of local variables can be changed from var
to let or const and from let to const.
The syntax in a configuration file is::

  [ruleType] ?not? varUplevel

* ruleType is the type of rule which will be executed. Proper values are:
  *check*, *search*, *count* and *fix*. For more information about the types of
  rules, please refer to the program's documentation. Check type will raise
  error when the declaration of the variable can be changed into let or
  const. Search type will list all declarations which can be updated and
  count type will show the amount of variables' declarations which can be
  updated. Fix type will try to update the type of the variable declaration,
  for example `var i = 1` will be updated to `let i = 1`. If variable was
  in a declaration block, it will be moved to a new declaration above the
  current position. It may produce an invalid code, especially if the
  variable's declaration depends on a previous declaration in the same
  block.
* optional word *not* means negation for the rule. Adding word *not* will
  change to inform only about variables' declarations which can't be updated
  to let or const.
* varUplevel is the name of the rule. It is case-insensitive, thus it can be
  set as *varuplevel*, *varUplevel* or *vArUpLeVeL*.

Disabling the rule
------------------
It is possible to disable the rule for a selected part of the checked code
by using pragma *ruleOff: "varUplevel"* in the element from which the rule
should be disabled or in code before it. For example, if the rule should
be disabled for variable `var i = 1`, the full declaration of it can be::

    var i {.ruleOff: "varUplevel".} = 1

To enable the rule again, the pragma *ruleOn: "varUplevel"* should be added in
the element which should be checked or in the code before it. For example,
if the rule should be re-enabled for `const a = 1`, the full declaration
should be::

    const a {.ruleOn: "varUplevel".} = 1

Examples
--------

1. Check if any declaration of local variable can be updated::

    check varUplevel

2. Search for declarations of local variables which can't be updated::

    search not varUplevel
