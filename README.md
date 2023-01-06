### General information

Nimalyzer is a static code analyzer for [Nim](https://github.com/nim-lang/Nim)
programming language. At this moment the project is in pre-alpha, organization
state, thus you will not find too much information yet.
If you read this file on GitHub: **please don't send pull requests here**.
All will be automatically closed. Any code propositions should go to the
[Fossil](https://www.laeran.pl/repositories/nimalyzer) repository.

**IMPORTANT:** If you read the file in the project code repository: This
version of the file is related to the future version of the shell. It may
contain information not present in released versions of the program. For
that information, please refer to the README.md file included into the release.

### Usage

1. To use Nimalyzer with your project, first you have to create a configuration
   file for it. At this moment, the whole documentation is in the configuration
   file used by the project itself (*config/nimalyzer.cfg*). In your
   configuration file you have to set at least one source file to check and at
   least one rule to use.

2. Run Nimanalyzer with path to your config file as the argument. For example:
   `nimalyzer config/nimalyzer.cfg` and just read its output. ;)

### How to install

#### Build from the source

You will need:

* [Nim compiler](https://nim-lang.org/install.html)
* [Contracts package](https://github.com/Udiknedormin/NimContracts)

You can install them manually or by using [Nimble](https://github.com/nim-lang/nimble).
In that second option, type `nimble install https://github.com/thindil/nimalyzer` to
install the shell and all dependencies. Generally it is recommended to use
`nimble release` to build the project in release (optimized) mode or
`nimble debug` to build it in the debug mode.

### License

The project released under 3-Clause BSD license.

---
That's all for now, as usual, I have probably forgotten about something important ;)

Bartek thindil Jasicki
