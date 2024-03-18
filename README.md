### General information

Nimalyzer is a static code analyzer for [Nim](https://github.com/nim-lang/Nim)
programming language. It allows checking a Nim source code against predefined
rules. Its design is inspired by [AdaControl](https://www.adalog.fr/en/adacontrol.html).
Nimalyzer can be used to enforce some design patterns or ensure that some
language constructs are present in a code, or not. For example, it can check if
all procedures have defined proper pragmas. Additionally, it can be used as an
advanced search through a code tool, for example find all public variables type
of *int* with name which starts with *newVar*. It is controlled by
configuration files containing a set of rules, their parameters and options
related to the program behavior.

At this moment, the project is in **alpha** stage, still many rules of the
program are missing, and should have a nice amount of bugs.

If you read this file on GitHub: **please don't send pull requests here**. All will
be automatically closed. Any code propositions should go to the
[Fossil](https://www.laeran.pl.eu.org/repositories/nimalyzer) repository.

**IMPORTANT:** If you read the file in the project code repository: This
version of the file is related to the future version of the program. It may
contain information not present in released versions of the program. For
that information, please refer to the README.md file included into the release.

### Usage

1. To use Nimalyzer with your project, first you have to create a configuration
   file for it. For the configuration file syntax, and the list of available
   rules, please refer to the project's documentation, available as
   reStructuredText in [doc](doc) directory. In your configuration file you
   will have to set at least one source file to check and at least one rule to
   use.

2. Run Nimanalyzer with path to your configuration file as the argument. For example:
   `nimalyzer config/nimalyzer.cfg` and just read its output. ;)

### How to install

#### Standalone binaries

Standalone binaries are available for FreeBSD, Linux and Windows in 64-bit
versions. They are available on the Download page. Just download and extract
them to the selected directory.

#### Build from the source

You will need:

* [Nim compiler](https://nim-lang.org/install.html) and its source code. If you
  installed the compiler from website or via *choosenim*, you should have installed
  it. Otherwise, you may need to install it manually either with *nimble install
  compiler@[yourCompilerVersion]* or with your package manager.
* [Contracts package](https://github.com/Udiknedormin/NimContracts)
* [Colored_logger package](https://github.com/4zv4l/colored_logger)

You can install them manually or by using [Nimble](https://github.com/nim-lang/nimble).
In that second option, type `nimble install nimalyzer` to install the program
and all dependencies. Generally it is recommended to use `nimble release` to
build the project in release (optimized) mode or `nimble debug` to build it
in the debug mode.

#### Build the project's documentation

To create HTML version of the project's documentation run command `nimble docs`
in the main project directory.

If you want to update the project's documentation, usually not needed, you have
to use *gendoc* tool included into the project.

1. Build the tool *gendoc*. In the main project's directory, execute command
   `nimble tools`. It will create needed tools and put them into *bin*
   directory.

2. In the man project's directory execute command `bin/gendoc`. It will update
   the project's documentation from the default configuration file and from the
   project's source code.

### License

The project released under 3-Clause BSD license.

---
That's all for now, as usual, I have probably forgotten about something important ;)

Bartek thindil Jasicki
