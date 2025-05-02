describe("acceptance: ", function()
    it("Runnning into timeout renders no explanations and outputs message", function()
        local buf = vim.api.nvim_create_buf(false, true)
        local before = vim.diagnostic.get(buf)["plugin-cronex.nvim"]
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "'* * * * *'" })
        vim.api.nvim_set_current_buf(buf)
        assert.are.equal(before, nil) -- should be emtpy because plugin is inactive
        require("cronex").setup({
            explainer = {
                -- args: 1) seconds 2) message to echo
                -- sleep 50 milliseconds and echo message
                cmd = { "bash", "scripts/tests/sleep_and_echo.sh", "0.05", "shouldn't show up" },
                timeout = 40 -- timeout after 40 milliseconds
            },
        })

        -- Spy on the messages to test the timeout notification
        local msgs = {}
        vim.notify = function(msg, ...)
            table.insert(msgs, msg)
        end

        vim.cmd("CronExplainedEnable")
        local co = coroutine.running()
        vim.defer_fn(function()
            coroutine.resume(co)
        end, 100)
        coroutine.yield()

        local diags = vim.diagnostic.get(buf)
        assert.are.same({}, diags)

        for _, msg in pairs(msgs) do
            local match = string.match(msg, "CronExplained Timeout with cmd ")
            assert.are.same(match, "CronExplained Timeout with cmd ")
        end
    end)
end)
