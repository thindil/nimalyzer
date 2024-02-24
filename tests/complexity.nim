include ../src/rules/complexity
import utils/helpers

runRuleTest(files = @["complexity"], validOptions = @["cyclomatic", "all", "2"],
    invalidOptions = @["randomoption", "anotheroption"], disabledChecks = {fixTests})
