## Bugs reporting

Bugs are not only problems or the program crashes, but also typos. If you
find any bug in the program, please report it at options available at [contact page](https://www.laeran.pl/repositories/nimalyzer/wiki?name=Contact).

### Some general hints about reporting bugs

* In "Title" field try to write short but not too general description of
  problem. Good example: "The program crash when opening directory". Bad
  example: "The program crashes often."
* In body/comment field try to write that much information about issue as
  possible. In most cases more information is better than less. General rule
  of good problem report is give enough information which allow reproducing
  problem by other people. It may be in form of steps which are needed for
  cause problem.

### Example of bug report:

Title: "The program crashed when trying to check the code"

Body:

1. Execute `nimalyzer config.cfg` [include the file *config.nim* and problematic code]
2. Wait a moment
3. The program crashes

## Features propositions

If you want to talk/propose changes in any existing the program feature or
mechanic, feel free to contact me via options available at [contact page](https://www.laeran.pl/repositories/nimalyzer/wiki?name=Contact).
General rule about propositions is same as for bugs reports - please,
try to write that much information as possible. This help us all better
understand purpose of your changes.

## Code propositions

### General information

If you want to start help in the program development, please consider starts
from something easy like fixing bugs. Before you been want to add new feature
to the program, please contact with me via options available at [contact page](https://www.laeran.pl/repositories/nimalyzer/wiki?name=Contact).
Same as with features proposition - your code may "collide" with my work and
it this moment you may just lose time by working on it. So it is better that
we first discuss your proposition. In any other case, fell free to fix my code.

### Coding standard

The project follows the default coding standards for [Nim](https://nim-lang.org/docs/nep1.html),
with additional extensions:

* All calls to subprograms must use named parameters.
* All subprograms must have pragmas: `raises` and `tags`.
* All subprograms should have pragma: `gcSafe`, unless they depends on unsafe
  subprograms.
* Subprograms shouldn't propagate exceptions, pragma `raises: []` unless they
  are low level subprograms, like type initialization, etc. The main shell's
  loop can't raise any exception.
* If possible, subprograms without side effects should be declared as functions.
* All subprograms must have a corresponding unit test, even if it is a very simple
  test.
* All subprograms must have written contracts, even it they are very simple.
* All subprograms must use their parameters.
* All subprograms and public declarations (variables, constants too) must have
  documentation.
* The code must be validated with the *nimalyzer* itself, by running it with
  configuration files *config/nimalyzer.cfg* for the program's code and
  *config/rules.cfg* for the program's rules' code.

### Code submission

A preferred way to submit your code is to use [tickets](https://www.laeran.pl/repositories/nimalyzer/ticket)
on the project page. Please attach to that ticket file with diff changes, the
best if done with command `fossil patch`. Another diff program will work too.
In that situation, please add information which program was used to create the
diff file. If you prefer you can also use other options from [the contact page](https://www.laeran.pl/repositories/nimalyzer/wiki?name=Contact).
