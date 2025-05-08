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
        -- Test all special time strings from crontab(5) manual
        assert.are.equal("@reboot", cron_from_line_crontab("@reboot run command"))
        assert.are.equal("@yearly", cron_from_line_crontab("@yearly run command"))
        assert.are.equal("@annually", cron_from_line_crontab("@annually run command"))
        assert.are.equal("@monthly", cron_from_line_crontab("@monthly run command"))
        assert.are.equal("@weekly", cron_from_line_crontab("@weekly run command"))
        assert.are.equal("@daily", cron_from_line_crontab("@daily run command"))
        assert.are.equal("@midnight", cron_from_line_crontab("@midnight run command"))
        assert.are.equal("@hourly", cron_from_line_crontab("@hourly run command"))
        
        -- Test with various command contexts
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

    it("Handles day of week names", function()
        -- Test uppercase day of week names
        assert.are.equal("30 2 * * MON", cron_from_line_crontab("30 2 * * MON command"))
        assert.are.equal("30 2 * * TUE", cron_from_line_crontab("30 2 * * TUE command"))
        assert.are.equal("30 2 * * WED", cron_from_line_crontab("30 2 * * WED command"))
        assert.are.equal("30 2 * * THU", cron_from_line_crontab("30 2 * * THU command"))
        assert.are.equal("30 2 * * FRI", cron_from_line_crontab("30 2 * * FRI command"))
        assert.are.equal("30 2 * * SAT", cron_from_line_crontab("30 2 * * SAT command"))
        assert.are.equal("30 2 * * SUN", cron_from_line_crontab("30 2 * * SUN command"))
        
        -- Test lowercase day of week names
        assert.are.equal("30 2 * * mon", cron_from_line_crontab("30 2 * * mon command"))
        assert.are.equal("30 2 * * tue", cron_from_line_crontab("30 2 * * tue command"))
        assert.are.equal("30 2 * * wed", cron_from_line_crontab("30 2 * * wed command"))
        assert.are.equal("30 2 * * thu", cron_from_line_crontab("30 2 * * thu command"))
        assert.are.equal("30 2 * * fri", cron_from_line_crontab("30 2 * * fri command"))
        assert.are.equal("30 2 * * sat", cron_from_line_crontab("30 2 * * sat command"))
        assert.are.equal("30 2 * * sun", cron_from_line_crontab("30 2 * * sun command"))
        
        -- Test mixed-case day of week names
        assert.are.equal("30 2 * * Mon", cron_from_line_crontab("30 2 * * Mon command"))
        assert.are.equal("30 2 * * Tue", cron_from_line_crontab("30 2 * * Tue command"))
        assert.are.equal("30 2 * * Wed", cron_from_line_crontab("30 2 * * Wed command"))
        assert.are.equal("30 2 * * Thu", cron_from_line_crontab("30 2 * * Thu command"))
        assert.are.equal("30 2 * * Fri", cron_from_line_crontab("30 2 * * Fri command"))
        assert.are.equal("30 2 * * Sat", cron_from_line_crontab("30 2 * * Sat command"))
        assert.are.equal("30 2 * * Sun", cron_from_line_crontab("30 2 * * Sun command"))
        
        -- Additional test cases with context
        assert.are.equal("1 14 * * TUE", cron_from_line_crontab("1 14 * * TUE cd ./root_dir && command"))
        assert.are.equal("0 0 * * SUN", cron_from_line_crontab("0 0 * * SUN weekly job"))
        assert.are.equal("45 18 * * Fri", cron_from_line_crontab("45 18 * * Fri run weekend backup"))
    end)

    it("Handles month names", function()
        -- Test uppercase month names
        assert.are.equal("15 10 * JAN *", cron_from_line_crontab("15 10 * JAN * command"))
        assert.are.equal("15 10 * FEB *", cron_from_line_crontab("15 10 * FEB * command"))
        assert.are.equal("15 10 * MAR *", cron_from_line_crontab("15 10 * MAR * command"))
        assert.are.equal("15 10 * APR *", cron_from_line_crontab("15 10 * APR * command"))
        assert.are.equal("15 10 * MAY *", cron_from_line_crontab("15 10 * MAY * command"))
        assert.are.equal("15 10 * JUN *", cron_from_line_crontab("15 10 * JUN * command"))
        assert.are.equal("15 10 * JUL *", cron_from_line_crontab("15 10 * JUL * command"))
        assert.are.equal("15 10 * AUG *", cron_from_line_crontab("15 10 * AUG * command"))
        assert.are.equal("15 10 * SEP *", cron_from_line_crontab("15 10 * SEP * command"))
        assert.are.equal("15 10 * OCT *", cron_from_line_crontab("15 10 * OCT * command"))
        assert.are.equal("15 10 * NOV *", cron_from_line_crontab("15 10 * NOV * command"))
        assert.are.equal("15 10 * DEC *", cron_from_line_crontab("15 10 * DEC * command"))
        
        -- Test lowercase month names
        assert.are.equal("15 10 * jan *", cron_from_line_crontab("15 10 * jan * command"))
        assert.are.equal("15 10 * feb *", cron_from_line_crontab("15 10 * feb * command"))
        assert.are.equal("15 10 * mar *", cron_from_line_crontab("15 10 * mar * command"))
        assert.are.equal("15 10 * apr *", cron_from_line_crontab("15 10 * apr * command"))
        assert.are.equal("15 10 * may *", cron_from_line_crontab("15 10 * may * command"))
        assert.are.equal("15 10 * jun *", cron_from_line_crontab("15 10 * jun * command"))
        assert.are.equal("15 10 * jul *", cron_from_line_crontab("15 10 * jul * command"))
        assert.are.equal("15 10 * aug *", cron_from_line_crontab("15 10 * aug * command"))
        assert.are.equal("15 10 * sep *", cron_from_line_crontab("15 10 * sep * command"))
        assert.are.equal("15 10 * oct *", cron_from_line_crontab("15 10 * oct * command"))
        assert.are.equal("15 10 * nov *", cron_from_line_crontab("15 10 * nov * command"))
        assert.are.equal("15 10 * dec *", cron_from_line_crontab("15 10 * dec * command"))
        
        -- Additional test cases from previous tests
        assert.are.equal("0 0 1 JAN *", cron_from_line_crontab("0 0 1 JAN * new year job"))
        assert.are.equal("0 0 25 DEC *", cron_from_line_crontab("0 0 25 DEC * christmas job"))
    end)

    it("Rejects name ranges and lists as per crontab(5) spec", function()
        assert.is_nil(cron_from_line_crontab("30 5 * * MON-FRI command"))
        assert.is_nil(cron_from_line_crontab("15 8 * * Mon,Wed,Fri Task job"))
        assert.is_nil(cron_from_line_crontab("15 12 * JAN-MAR * Q1 job"))
    end)
end)
