describe("acceptance: ", function()
    it("Detect cron on buffer and set diagnostics with custom setup opts", function()
        -- Make mock buffer
        local buf = vim.api.nvim_create_buf(false, true)
        local before = vim.diagnostic.get(buf)["plugin-cronex.nvim"]
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            "hello",
            "world",
            "'* * * * *'",
            "i have no cron",
            "'1 * * 1 * *'",
        })
        vim.api.nvim_set_current_buf(buf)
        assert.are.equal(before, nil) -- should be emtpy because plugin is inactive
        local cronex = require("cronex")
        cronex.setup({
            explainer = {
                cmd = { "echo", "great-explanation" },
            },
            format = function(explanation)
                return "hello-" .. explanation
            end,
        })
        vim.cmd("CronExplainedEnable")

        -- Wait for system call to get back with cron explainations
        local co = coroutine.running()
        vim.defer_fn(function()
            coroutine.resume(co)
        end, 1000)
        coroutine.yield() --The test will only reach here after one second, when the deferred function runs.

        local diags = vim.diagnostic.get(buf)
        local ns = vim.api.nvim_get_namespaces()["plugin-cronex.nvim"]
        local got = {}
        for _, diag in pairs(diags) do
            table.insert(got, {
                bufnr = diag.bufnr,
                lnum = diag.lnum,
                message = diag.message,
                namespace = diag.namespace,
                severity = diag.severity,
            })
        end
        table.sort(got, function(a, b)
            return a.lnum < b.lnum
        end)
        local expected = {
            {
                bufnr = buf,
                lnum = 2,
                message = "hello-great-explanation * * * * *\n",
                namespace = ns,
                severity = 4,
            },
            {
                bufnr = buf,
                lnum = 4,
                message = "hello-great-explanation 1 * * 1 * *\n",
                namespace = ns,
                severity = 4,
            },
        }
        table.sort(expected, function(a, b)
            return a.lnum < b.lnum
        end)
        assert.are.same(got, expected)
        -- Deactivating plugin should remove Diagnostics
        vim.cmd("CronExplainedDisable")
        assert.are.same(vim.diagnostic.get(buf), {})
    end)
end)
