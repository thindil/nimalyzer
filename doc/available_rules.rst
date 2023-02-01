===============
Available rules
===============

.. default-role:: code
.. contents::

Hasentity rule
==============
The rule to check if the selected procedure has the selected entities, like
procedures, constants, etc. with the selected names. The syntax in a
configuration file is::

  [ruleType] ?not? hasentity [entityType] [entityName]

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

To look only for global entities, add `*` to the end of the entityName
parameter. Setting it to *MyProc\** will look only for global entities
which full name is MyProc.

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

Paramsused rule
===============
The rule to check if the selected procedure uses all its parameter
The syntax in a configuration file is::

  [ruleType] ?not? parametersUsed

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

Examples
--------

1. Check if all procedures in module uses their parameters::

    check parametersUsed

2. Search for all procedures which don't use their all parameters::

    search not parametersUsed
