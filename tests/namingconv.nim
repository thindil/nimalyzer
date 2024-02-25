include ../src/rules/namingconv
import utils/helpers

runRuleTest(files = @["namingconv"], validOptions = @["variables",
    "[a-z][a-zA-Z0-9_]"], invalidOptions = @[], disabledChecks = {fixTests})
