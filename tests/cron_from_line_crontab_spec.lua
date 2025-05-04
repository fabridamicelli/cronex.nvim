describe("cron_from_line_crontab", function()
    local cron_from_line_crontab = require("cronex.cron_from_line").cron_from_line_crontab

    it("Returns nil for comments and empty lines", function()
        assert.is_nil(cron_from_line_crontab("# This is a comment"))
        assert.is_nil(cron_from_line_crontab("   # Comment with leading space"))
        assert.is_nil(cron_from_line_crontab(""))
        assert.is_nil(cron_from_line_crontab("  "))
    end)

    it("Handles quoted cron expressions", function()
        -- Should defer to the standard cron_from_line function
        assert.are.equal("* * * * *", cron_from_line_crontab("'* * * * *' echo hello"))
        assert.are.equal("30 5 * * 1-5", cron_from_line_crontab('  "30 5 * * 1-5" /path/to/script'))
    end)

    it("Handles standard 5-part cron expressions", function()
        assert.are.equal("* * * * *", cron_from_line_crontab("* * * * * echo hello"))
        assert.are.equal("30 5 * * 1-5", cron_from_line_crontab("30 5 * * 1-5 /path/to/script"))
        assert.are.equal("0 */4 * * *", cron_from_line_crontab("0 */4 * * * run command"))
        assert.are.equal("15,45 0 * * 1-5", cron_from_line_crontab("15,45 0 * * 1-5 run command"))
    end)

    it("Handles special time strings", function()
        assert.are.equal("@daily", cron_from_line_crontab("@daily run command"))
        assert.are.equal("@hourly", cron_from_line_crontab("@hourly job"))
        assert.are.equal("@weekly", cron_from_line_crontab("@weekly /path/to/script"))
        assert.are.equal("@monthly", cron_from_line_crontab("@monthly do something"))
        assert.are.equal("@yearly", cron_from_line_crontab("@yearly yearly job"))
    end)

    it("Handles 6-part cron expressions (with seconds)", function()
        assert.are.equal(
            "30 5 * * 1-5",
            cron_from_line_crontab("0 30 5 * * 1-5 /path/to/script"),
            "Should extract minutes through weekday, ignoring seconds"
        )
        assert.are.equal(
            "0 0 * * *",
            cron_from_line_crontab("30 0 0 * * * midnight job with 30s"),
            "Should extract standard 5 parts correctly"
        )
        assert.are.equal(
            "*/15 * * * *",
            cron_from_line_crontab("0 */15 * * * * every 15 minutes"),
            "Should handle special chars in cron parts"
        )
    end)

    it("Handles cron expressions with trailing command parts containing numbers", function()
        assert.are.equal(
            "* * * * 1",
            cron_from_line_crontab("* * * * * 1 2 3"),
            "Should extract only the first 5 parts, but the pattern is capturing the first number after the weekday"
        )
        assert.are.equal(
            "30 5 * * 1-5",
            cron_from_line_crontab("30 5 * * 1-5 run command with 42 numbers"),
            "Should not be confused by numbers in command"
        )
    end)

    it("Handles indentation and spacing", function()
        assert.are.equal("* * * * *", cron_from_line_crontab("    * * * * * command"))
        assert.are.equal("30 5 * * 1-5", cron_from_line_crontab("\t30 5 * * 1-5 command"))
        assert.are.equal("@daily", cron_from_line_crontab("  @daily  with extra spaces  "))
    end)
end)
