describe("acceptance: crontab file pattern", function()
    local cronex
    local buf
    local orig_buf
    
    -- Helper function to wait for async operations
    local function wait(ms)
        local co = coroutine.running()
        vim.defer_fn(function()
            coroutine.resume(co)
        end, ms or 1000)
        coroutine.yield()
    end
    
    describe("with quoted cron expressions", function()
        -- Setup before each test
        before_each(function()
            -- Save current buffer to restore later
            orig_buf = vim.api.nvim_get_current_buf()
            
            -- Create mock buffer with .crontab extension
            buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_name(buf, "test.crontab")
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
                "'* * * * *' command",
                "# this line has no cron",
            })
            
            -- Load but don't setup yet
            cronex = require("cronex")
        end)
        
        -- Cleanup after each test
        after_each(function()
            -- Disable plugin and clear diagnostics
            vim.cmd("CronExplainedDisable")
            
            -- Reset buffer to original
            vim.api.nvim_set_current_buf(orig_buf)
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end)
        
        it("Activates plugin for .crontab files", function()
            -- Setup plugin with .crontab in file_patterns
            cronex.setup({
                file_patterns = { "*.crontab" },
                explainer = {
                    cmd = { "echo", "test-explanation" }
                }
            })
            
            -- Set current buffer and manually trigger the BufEnter autocmd
            vim.api.nvim_set_current_buf(buf)
            vim.cmd("doautocmd BufEnter")
            
            -- Wait for async operations to complete
            wait()
            
            -- Get plugin namespace
            local ns = vim.api.nvim_get_namespaces()["plugin-cronex.nvim"]
            assert.is_not_nil(ns, "Plugin namespace should exist")
            
            -- Get diagnostics
            local diags = vim.diagnostic.get(buf)
            assert.is_not_nil(diags, "Diagnostics should exist")
            assert.is_true(#diags > 0, "Should have diagnostics for cron line")
            
            -- Verify the diagnostic is on the correct line and has expected content
            local cron_diag = diags[1]
            assert.are.equal(0, cron_diag.lnum, "Diagnostic should be on the first line")
            assert.truthy(string.match(cron_diag.message, "test%-explanation"), 
                        "Diagnostic message should contain explainer output")
            assert.are.equal(ns, cron_diag.namespace, "Diagnostic should be in the plugin namespace")
            
            -- Verify cleanup works
            vim.cmd("CronExplainedDisable")
            local after_diags = vim.diagnostic.get(buf)
            assert.are.same({}, after_diags, "Diagnostics should be cleared after disabling")
        end)
        
        it("Manually enables for .crontab file", function()
            -- Setup plugin without .crontab in patterns
            cronex.setup({
                file_patterns = { "*.yml" }, -- Deliberately exclude crontab
                explainer = {
                    cmd = { "echo", "test-explanation" }
                }
            })
            
            -- Set buffer and check no diagnostics yet
            vim.api.nvim_set_current_buf(buf)
            local before_diags = vim.diagnostic.get(buf)
            assert.are.same({}, before_diags, "Should have no diagnostics before enabling")
            
            -- Manually enable
            vim.cmd("CronExplainedEnable")
            wait()
            
            -- Check diagnostics after manual enable
            local after_diags = vim.diagnostic.get(buf)
            assert.is_true(#after_diags > 0, "Should have diagnostics after manual enable")
        end)
    end)

    describe("with unquoted cron expressions (standard crontab format)", function()
        local unquoted_buf
        
        before_each(function()
            -- Save current buffer to restore later
            orig_buf = vim.api.nvim_get_current_buf()
            
            -- Create mock buffer with typical crontab format (no quotes)
            unquoted_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_name(unquoted_buf, "test.crontab")
            vim.api.nvim_buf_set_lines(unquoted_buf, 0, -1, false, {
                "* * * * * /usr/bin/command",
                "30 5 * * 1-5 /path/to/script",
                "# this line has no cron",
                "@daily /another/command"
            })
            
            -- Load but don't setup yet
            cronex = require("cronex")
        end)
        
        after_each(function()
            -- Disable plugin and clear diagnostics
            vim.cmd("CronExplainedDisable")
            
            -- Reset buffer to original
            vim.api.nvim_set_current_buf(orig_buf)
            pcall(vim.api.nvim_buf_delete, unquoted_buf, { force = true })
        end)
        
        it("Recognizes unquoted crontab expressions", function()
            -- Setup plugin with custom crontab extractor
            cronex.setup({
                file_patterns = { "*.crontab" },
                extractor = {
                    -- This will be implemented in our custom extractor
                    cron_from_line = require("cronex.cron_from_line").cron_from_line_crontab,
                    extract = require("cronex.extract").extract
                },
                explainer = {
                    cmd = { "echo", "test-explanation" }
                }
            })
            
            -- Set current buffer and enable plugin
            vim.api.nvim_set_current_buf(unquoted_buf)
            vim.cmd("CronExplainedEnable")
            
            -- Wait for async operations to complete
            wait()
            
            -- Get diagnostics
            local diags = vim.diagnostic.get(unquoted_buf)
            assert.is_not_nil(diags, "Diagnostics should exist")
            assert.is_true(#diags > 0, "Should have diagnostics for cron lines")
            
            -- Should have diagnostics for both cron lines
            assert.are.equal(3, #diags, "Should have 3 diagnostics (2 standard cron lines + @daily)")
            
            -- Verify first cron line has explanation
            local has_first_cron = false
            local has_second_cron = false
            local has_at_daily = false
            
            for _, diag in ipairs(diags) do
                if diag.lnum == 0 then
                    has_first_cron = true
                elseif diag.lnum == 1 then
                    has_second_cron = true
                elseif diag.lnum == 3 then
                    has_at_daily = true
                end
            end
            
            assert.is_true(has_first_cron, "Should recognize '* * * * *' pattern")
            assert.is_true(has_second_cron, "Should recognize '30 5 * * 1-5' pattern")
            assert.is_true(has_at_daily, "Should recognize '@daily' special syntax")
        end)
    end)
end)