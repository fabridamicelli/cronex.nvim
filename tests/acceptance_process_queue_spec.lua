--- Tests for process queue and concurrency control mechanism
describe("acceptance: process queue", function()
    -- Setup and teardown to ensure clean state between tests
    local original_system = nil
    
    before_each(function()
        -- Save original function for restoration
        original_system = vim.system
    end)
    
    after_each(function()
        -- Always restore the original system function
        vim.system = original_system
        -- Clean up any open buffers
        vim.cmd("silent! %bdelete!")
    end)
    
    it("respects max_concurrent setting to prevent 'too many open files' error", function()
        -- Create a test buffer with many cron expressions
        local buf = vim.api.nvim_create_buf(false, true)
        
        -- Constants for test configuration
        local MAX_CONCURRENT = 10
        local NUM_EXPRESSIONS = 100
        
        -- Create many lines with cron expressions - this would normally
        -- cause "too many open files" without our process queue system
        local lines = {}
        for i = 1, NUM_EXPRESSIONS do
            table.insert(lines, string.format("'%d * * * *' # test line %d", i % 60, i))
        end
        
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_set_current_buf(buf)
        
        -- Test metrics
        local metrics = {
            call_count = 0,       -- Total number of calls made
            max_concurrent = 0,   -- Maximum observed concurrent processes
            active_count = 0,     -- Current active processes
            called_lines = {}     -- List of processed cron expressions
        }
        
        -- Mock implementation of vim.system that tracks concurrency
        vim.system = function(cmd, opts, on_exit)
            -- Track metrics
            metrics.call_count = metrics.call_count + 1
            metrics.active_count = metrics.active_count + 1
            metrics.max_concurrent = math.max(metrics.max_concurrent, metrics.active_count)
            
            -- Track which cron expressions are processed
            local cron_expression = cmd[#cmd]
            table.insert(metrics.called_lines, cron_expression)
            
            -- Simulate async behavior with small controlled delay
            -- This creates enough concurrent operations to test queue behavior
            vim.defer_fn(function()
                -- Simulate process completion
                metrics.active_count = metrics.active_count - 1
                on_exit({
                    stdout = "Test explanation for " .. cron_expression,
                    stderr = "",
                    code = 0
                })
            end, 5) -- Short timeout to make test run faster
            
            return true -- Match original function return value
        end
        
        -- Configure cronex with a deliberately small max_concurrent value
        -- to exercise the concurrency limits
        require("cronex").setup({
            explainer = {
                cmd = "echo",
                args = {},
                max_concurrent = MAX_CONCURRENT,
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
        
        -- Assert that the process queue properly limited concurrency
        assert.is_true(
            metrics.max_concurrent <= MAX_CONCURRENT, 
            string.format(
                "Should respect max_concurrent limit of %d (got %d)", 
                MAX_CONCURRENT,
                metrics.max_concurrent
            )
        )
        
        -- Assert that all cron expressions were processed
        assert.are.equal(
            NUM_EXPRESSIONS, 
            metrics.call_count, 
            "All cron expressions should be processed"
        )
        
        -- Disable plugin to clean up
        vim.cmd("CronExplainedDisable")
        
        -- Verify diagnostics were removed
        assert.are.same({}, vim.diagnostic.get(buf), "Diagnostics should be cleared after disable")
    end)
end)