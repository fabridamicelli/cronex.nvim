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
end)
