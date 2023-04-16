Various tools related to the project's development. To build them, use command
`nimble tools` in the main project's directory

* gendoc.nim  - the simple program to generate the project's documentation as
                restructuredText files in doc directory. To generate the
                documentation, build the tool and then run it from the main
                project's directory.
* genrule.nim - the simple program to generate the project's rules' base files
                in src/rules directory. To generate a rule file, built the tool
                and then run it from the main project's directory.
* rule.txt    - the template for the program's rules generation. Used by the
                genrule program.
