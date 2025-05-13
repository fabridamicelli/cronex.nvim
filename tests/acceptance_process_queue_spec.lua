describe("acceptance: ", function()
    it("Successfully processes many cron expressions without 'too many open files' error", function()
        -- Create a test buffer with many cron expressions
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- Create 100 lines with cron expressions - this would normally
        -- cause "too many open files" without our process queue system
        local lines = {}
        for i = 1, 100 do
            table.insert(lines, string.format("'%d * * * *' # test line %d", i % 60, i))
        end
        
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_set_current_buf(buf)
        
        -- Mock the vim.system function to track calls
        local original_system = vim.system
        local call_count = 0
        local max_concurrent = 0
        local active_count = 0
        local called_lines = {}
        
        -- Replace vim.system with our instrumented version
        vim.system = function(cmd, opts, on_exit)
            call_count = call_count + 1
            active_count = active_count + 1
            max_concurrent = math.max(max_concurrent, active_count)
            
            -- Add the cron expression to our tracking
            table.insert(called_lines, cmd[#cmd])
            
            -- Schedule the completion to simulate async behavior
            vim.defer_fn(function()
                active_count = active_count - 1
                on_exit({
                    stdout = "Test explanation for " .. cmd[#cmd],
                    stderr = "",
                    code = 0
                })
            end, 5) -- Short timeout to make test run faster
            
            return true
        end
        
        -- Set up cronex with a small max_concurrent value
        require("cronex").setup({
            explainer = {
                cmd = "echo",
                args = {},
                max_concurrent = 10, -- Limit to 10 concurrent processes
            }
        })
        
        -- Enable the plugin which will trigger processing
        vim.cmd("CronExplainedEnable")
        
        -- Wait for all processes to complete
        local co = coroutine.running()
        vim.defer_fn(function()
            coroutine.resume(co)
        end, 1000)
        coroutine.yield()
        
        -- Restore the original vim.system
        vim.system = original_system
        
        -- Assert that we respected the concurrent process limit
        assert.is_true(max_concurrent <= 10, "Should respect max_concurrent limit")
        
        -- Clean up
        vim.cmd("CronExplainedDisable")
        assert.are.same({}, vim.diagnostic.get(buf))
    end)
end)