local cron_from_line = require("cronex.cron_from_line").cron_from_line
local eq = assert.are.equal

local assert_all_eq = function(inputs, expected)
    for _, inp in pairs(inputs) do
        local out = cron_from_line(inp)
        eq(out, expected)
    end
end

describe("cron_from_line.cron_from_line - Invalid cron:", function()
    it("empty lines are nil", function()
        local lines = {
            '""',
            '" "',
            "''",
            "' '",
        }
        assert_all_eq(lines, nil)
    end)

    it("naked crons are nil", function()
        local lines = {
            "* * * * *",
            "* * * * * *",
            "* * * * * * *",
            "cron: * * * * * *",
        }
        assert_all_eq(lines, nil)
    end)

    it("incomplete crons are nil", function()
        local lines = {
            '"1 2 3"',
            '"* * *"',
            "'* * *'",
            '"1 * *"',
            "'2 * *'",
            '"* * * *"',
            "'* * * *'",
        }
        assert_all_eq(lines, nil)
    end)

    it("more than 1 cron per line is nil", function()
        local lines = {
            '"* * *" "* * *"',
            "'* * * * *' '* * *'",
            '"* * * * *" "* * *"',
            '"* * * * *" "* * 1 1 *"',
            '"* * * * * " "* *"',
            '"* * * *" "*"',
            '"* * * * *" "* * * * *"',
        }
        assert_all_eq(lines, nil)
    end)

    it("invalid cron expressions are nil", function()
        local invalid_crons = {
            '"1 2 3"',
            'cron: "1 5 1 * 2 * 2 1 *"',
            'cron: "1 5 1 * 2 * 2 1 *"',
            'cron: "1 5 1 * 2 * 2 1"',
            'cron : "1 5 1 * 2 * 2 1 *"',
            'cron : "1 5 1 * 2 * 2 1 *"',
        }
        assert_all_eq(invalid_crons, nil)
    end)

    it("YAML-like expressions with @include are nil", function()
        local yaml_expressions = {
            -- Direct @include patterns
            '"@include"',
            '"@include universal-constants.yml#Universal_Legend"',
            '"@include flag-inheritance.yml#Universal_Always"',
            "'@include universal-constants.yml#Universal_Legend'",
            "'@include flag-inheritance.yml#Universal_Always'",
            
            -- Embedded in YAML structure
            'Legend: "@include universal-constants.yml#Universal_Legend"',
            'Flags: "@include flag-inheritance.yml#Universal_Always"',
            
            -- Expressions with invalid text that cronstrue errors on
            '"2-5 pages for standard analysis"',
            '"755 for dirs, 644 for files"',
            '"for each file in directory"',
            
            -- Mixed invalid expressions
            '"@see recovery-state-patterns.yml#Error_Classification"',
            '"@see research-patterns.yml#Research_Validation"',
        }
        assert_all_eq(yaml_expressions, nil)
    end)

    it("Real-world YAML configuration lines are nil (integration test)", function()
        -- These are actual lines from a YAML file that caused cronstrue errors
        local real_yaml_lines = {
            -- Lines that caused "Unknown special expression" error
            '@include universal-constants.yml#Universal_Legend',
            '  1_Purpose: "**Purpose**: Single sentence describing command function"',
            '  2_Legend: "@include universal-constants.yml#Universal_Legend"',
            '  5_Flags: "@include flag-inheritance.yml#Universal_Always"',
            
            -- Lines that caused "Expression contains invalid values: 'pages'" error
            '    Articles: "Remove \'the|a|an\' where clear"',
            '  2-5 pages for standard analysis.',
            '    Overall: "~70% average reduction"',
            
            -- Lines that caused "Expression contains invalid values: 'for'" error  
            '  755 for dirs, 644 for files.',
            '    Verbose_Phrases: "\'in order to\'→\'to\' | \'make sure\'→\'ensure\'"',
            '  Structure_Priority:',
            '    1_YAML: "Most compact structured data"',
            
            -- Other YAML patterns that might be mistaken for cron
            'Required_Sections:',
            '  Analysis: ["analyze", "load", "explain", "troubleshoot"]',
            '  Build: ["build", "spawn"]',
            'Command_Categories:',
            '  analyze→improve: "Use found issues as targets + priority ranking"',
            '  build→test: "Focus on changed modules + integration points"',
            
            -- Edge cases with quotes and special characters
            'Planning: "@see flag-inheritance.yml#Universal_Always"',
            'MCP_Control: "@see flag-inheritance.yml#MCP_Control"',
            'Thinking_Modes: "@see flag-inheritance.yml#Thinking_Modes"',
        }
        assert_all_eq(real_yaml_lines, nil)
    end)
end)

describe("cron_from_line.cron_from_line - Valid cron:", function()
    it("extract pure cron", function()
        -- pairs (input, expected)
        local items = {
            -- pure line
            --double quoted
            ['"* * * * *"'] = "* * * * *",
            ['"* * * * * *"'] = "* * * * * *",
            ['"* * * * * * *"'] = "* * * * * * *",
            --single quoted
            ["'* * * * *'"] = "* * * * *",
            ["'* * * * * *'"] = "* * * * * *",
            ["'* * * * * * *'"] = "* * * * * * *",
        }
        for inp, exp in pairs(items) do
            eq(cron_from_line(inp), exp)
        end
    end)

    it("extract embedded cron", function()
        local items = {
            -- mixed line
            --double quoted
            ['cron: "* * * * *"'] = "* * * * *",
            ['cron: "* * * * * *"'] = "* * * * * *",
            ['cron: "* * * * * * *"'] = "* * * * * * *",
            --single quoted
            ["cron: '* * * * *'"] = "* * * * *",
            ["cron: '* * * * * *'"] = "* * * * * *",
            ["cron: '* * * * * * *'"] = "* * * * * * *",
        }
        for inp, exp in pairs(items) do
            eq(cron_from_line(inp), exp)
        end
    end)

    it("extract cron starting with space", function()
        local items = {
            --double quoted
            ['cron: " * * * * *"'] = "* * * * *",
            ['cron: " * * * * * *"'] = "* * * * * *",
            ['cron: " * * * * * * *"'] = "* * * * * * *",
            --single quoted
            ["cron: ' * * * * *'"] = "* * * * *",
            ["cron: ' * * * * * *'"] = "* * * * * *",
            ["cron: ' * * * * * * *'"] = "* * * * * * *",
        }
        for inp, exp in pairs(items) do
            eq(cron_from_line(inp), exp)
        end
    end)

    it("extract cron ending with space", function()
        local items = {
            --double quoted
            ['cron: "* * * * * "'] = "* * * * *",
            ['cron: "* * * * * * "'] = "* * * * * *",
            ['cron: "* * * * * * * "'] = "* * * * * * *",
            --single quoted
            ["cron: '* * * * * '"] = "* * * * *",
            ["cron: '* * * * * * '"] = "* * * * * *",
            ["cron: '* * * * * * * '"] = "* * * * * * *",
        }
        for inp, exp in pairs(items) do
            eq(cron_from_line(inp), exp)
        end
    end)

    it("extract cron with numbers", function()
        local items = {
            --double quoted
            ['cron: "1 * * * *"'] = "1 * * * *",
            ['cron: "1 * * * * *"'] = "1 * * * * *",
            ['cron: "1 * * * * * *"'] = "1 * * * * * *",

            ['cron: "1 2 * * *"'] = "1 2 * * *",
            ['cron: "1 2 * * * *"'] = "1 2 * * * *",
            ['cron: "1 2 * * * * *"'] = "1 2 * * * * *",

            ['cron: "1 2 3 * *"'] = "1 2 3 * *",
            ['cron: "1 2 3 * * *"'] = "1 2 3 * * *",
            ['cron: "1 2 3 * * * *"'] = "1 2 3 * * * *",

            ['cron: "1 2 3 4 *"'] = "1 2 3 4 *",
            ['cron: "1 2 3 4 * *"'] = "1 2 3 4 * *",
            ['cron: "1 2 3 4 * * *"'] = "1 2 3 4 * * *",

            ['cron: "1 2 3 4 5"'] = "1 2 3 4 5",
            ['cron: "1 2 3 4 5 *"'] = "1 2 3 4 5 *",
            ['cron: "1 2 3 4 5 * *"'] = "1 2 3 4 5 * *",

            ['cron: "1 2 3 4 5 6"'] = "1 2 3 4 5 6",
            ['cron: "1 2 3 4 5 6 *"'] = "1 2 3 4 5 6 *",

            ['cron: "1 2 3 4 5 6 7"'] = "1 2 3 4 5 6 7",

            -- single quoted
            ["cron: '1 * * * *'"] = "1 * * * *",
            ["cron: '1 * * * * *'"] = "1 * * * * *",
            ["cron: '1 * * * * * *'"] = "1 * * * * * *",

            ["cron: '1 2 * * *'"] = "1 2 * * *",
            ["cron: '1 2 * * * *'"] = "1 2 * * * *",
            ["cron: '1 2 * * * * *'"] = "1 2 * * * * *",

            ["cron: '1 2 3 * *'"] = "1 2 3 * *",
            ["cron: '1 2 3 * * *'"] = "1 2 3 * * *",
            ["cron: '1 2 3 * * * *'"] = "1 2 3 * * * *",

            ["cron: '1 2 3 4 *'"] = "1 2 3 4 *",
            ["cron: '1 2 3 4 * *'"] = "1 2 3 4 * *",
            ["cron: '1 2 3 4 * * *'"] = "1 2 3 4 * * *",

            ["cron: '1 2 3 4 5'"] = "1 2 3 4 5",
            ["cron: '1 2 3 4 5 *'"] = "1 2 3 4 5 *",
            ["cron: '1 2 3 4 5 * *'"] = "1 2 3 4 5 * *",

            ["cron: '1 2 3 4 5 6'"] = "1 2 3 4 5 6",
            ["cron: '1 2 3 4 5 6 *'"] = "1 2 3 4 5 6 *",

            ["cron: '1 2 3 4 5 6 7'"] = "1 2 3 4 5 6 7",
        }
        for inp, exp in pairs(items) do
            eq(cron_from_line(inp), exp)
        end
    end)

    it("extract complex cron", function()
        local items = {
            --double quoted
            ['cron: "1,2 /3 * * 2-5"'] = "1,2 /3 * * 2-5",
            ['cron: "1,2 /3 2-4 2/2-3 2-5"'] = "1,2 /3 2-4 2/2-3 2-5",
            ['cron : "*/1 5 2 * 2 * 2"'] = "*/1 5 2 * 2 * 2",
            ['cron : "1-3 5,4 */2-4 * 1-2 * 2,3"'] = "1-3 5,4 */2-4 * 1-2 * 2,3",
            ['cron: "8,28,48 * * * *"'] = "8,28,48 * * * *",
            ['cron: "1,2,3 /3,5 2-4 2/2-3 2-5"'] = "1,2,3 /3,5 2-4 2/2-3 2-5",
            ['cron: "1,2,3 2,3,4 1,3,4 7 4,5,6"'] = "1,2,3 2,3,4 1,3,4 7 4,5,6",
            ['cron: "1,22,33 2,3,4 1,3,4 7 4,5,6"'] = "1,22,33 2,3,4 1,3,4 7 4,5,6",

            -- single quoted
            ["cron: '1,2 /3 * * 2-5'"] = "1,2 /3 * * 2-5",
            ["cron: '1,2 /3 2-4 2/2-3 2-5'"] = "1,2 /3 2-4 2/2-3 2-5",
            ["cron : '*/1 5 2 * 2 * 2'"] = "*/1 5 2 * 2 * 2",
            ["cron : '1-3 5,4 */2-4 * 1-2 * 2,3'"] = "1-3 5,4 */2-4 * 1-2 * 2,3",
            ["cron: '8,28,48 * * * *'"] = "8,28,48 * * * *",
            ["cron: '1,2,3 /3,5 2-4 2/2-3 2-5'"] = "1,2,3 /3,5 2-4 2/2-3 2-5",
            ["cron: '1,2,3 2,3,4 1,3,4 7 4,5,6'"] = "1,2,3 2,3,4 1,3,4 7 4,5,6",
            ["cron: '1,22,33 2,3,4 1,3,4 7 4,5,6'"] = "1,22,33 2,3,4 1,3,4 7 4,5,6",
        }
        for inp, exp in pairs(items) do
            eq(cron_from_line(inp), exp)
        end
    end)

    it("extract cron with days,weeks, months,# and ?", function()
        local items = {
            --double quoted
            ['cron: "0 * 2 1 Jan-Mar *"'] = "0 * 2 1 Jan-Mar *",
            ['cron: "0 23 * 1 * 2015-2016"'] = "0 23 * 1 * 2015-2016",
            ['cron: "0 23 1 * ?"'] = "0 23 1 * ?",
            ['cron: "0 23 1 * Mon"'] = "0 23 1 * Mon",
            ['cron: "0 23 ? * MON-FRI"'] = "0 23 ? * MON-FRI",
            ['cron: "23 12 * * 1#2"'] = "23 12 * * 1#2",
            ['cron: "* * LW * *"'] = "* * LW * *",
            ['cron: "* * WL * *"'] = "* * WL * *",
            ['cron: "* * 13W * *"'] = "* * 13W * *",
            ['cron: "0 20 1-10,20-L * *"'] = "0 20 1-10,20-L * *",
            ['cron: "* 23 12 * JAN-MAR * 2013-2015"'] = "* 23 12 * JAN-MAR * 2013-2015",
            ['cron: "0 15 6 1 1 ? 1970/2"'] = "0 15 6 1 1 ? 1970/2",
            ['cron: "* * * * MON#3"'] = "* * * * MON#3",
            ['cron: "23 12 * * SUN#2"'] = "23 12 * * SUN#2",
            ['cron: "0 00 10 ? * MON-THU,SUN *"'] = "0 00 10 ? * MON-THU,SUN *",

            -- single quoted
            ["cron: '0 * 2 1 Jan-Mar *'"] = "0 * 2 1 Jan-Mar *",
            ["cron: '0 23 * 1 * 2015-2016'"] = "0 23 * 1 * 2015-2016",
            ["cron: '0 23 1 * ?'"] = "0 23 1 * ?",
            ["cron: '0 23 1 * Mon'"] = "0 23 1 * Mon",
            ["cron: '0 23 ? * MON-FRI'"] = "0 23 ? * MON-FRI",
            ["cron: '23 12 * * 1#2'"] = "23 12 * * 1#2",
            ["cron: '* * LW * *'"] = "* * LW * *",
            ["cron: '* * WL * *'"] = "* * WL * *",
            ["cron: '* * 13W * *'"] = "* * 13W * *",
            ["cron: '0 20 1-10,20-L * *'"] = "0 20 1-10,20-L * *",
            ["cron: '* 23 12 * JAN-MAR * 2013-2015'"] = "* 23 12 * JAN-MAR * 2013-2015",
            ["cron: '0 15 6 1 1 ? 1970/2'"] = "0 15 6 1 1 ? 1970/2",
            ["cron: '* * * * MON#3'"] = "* * * * MON#3",
            ["cron: '23 12 * * SUN#2'"] = "23 12 * * SUN#2",
            ["cron: '0 00 10 ? * MON-THU,SUN *'"] = "0 00 10 ? * MON-THU,SUN *",
        }
        for inp, exp in pairs(items) do
            eq(cron_from_line(inp), exp)
        end
    end)

    it("extract special cron expressions", function()
        local items = {
            -- Double quoted special expressions
            ['"@yearly"'] = "@yearly",
            ['"@annually"'] = "@annually",
            ['"@monthly"'] = "@monthly",
            ['"@weekly"'] = "@weekly",
            ['"@daily"'] = "@daily",
            ['"@midnight"'] = "@midnight",
            ['"@hourly"'] = "@hourly",
            ['"@reboot"'] = "@reboot",
            
            -- Single quoted special expressions
            ["'@yearly'"] = "@yearly",
            ["'@annually'"] = "@annually",
            ["'@monthly'"] = "@monthly",
            ["'@weekly'"] = "@weekly",
            ["'@daily'"] = "@daily",
            ["'@midnight'"] = "@midnight",
            ["'@hourly'"] = "@hourly",
            ["'@reboot'"] = "@reboot",
            
            -- Embedded in lines
            ['cron: "@daily"'] = "@daily",
            ["schedule: '@hourly'"] = "@hourly",
            ['task: "@reboot"'] = "@reboot",
        }
        for inp, exp in pairs(items) do
            eq(cron_from_line(inp), exp)
        end
    end)
end)
