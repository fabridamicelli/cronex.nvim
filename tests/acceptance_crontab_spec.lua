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
                    cmd = { "echo", "test-explanation" },
                },
            })

            -- Set current buffer and manually trigger the BufEnter autocmd
            vim.api.nvim_set_current_buf(buf)
            vim.cmd("doautocmd BufEnter")

            -- Wait for async operations to complete
            wait()

            -- Get plugin namespace
            local ns = vim.api.nvim_get_namespaces()["plugin-cronex.nvim"]
            assert.is_not_nil(ns, "Plugin namespace should exist")

            -- Get diagnostics for the plugin namespace and verify them
            local diags = vim.diagnostic.get(buf, { namespace = ns })
            assert.is_true(#diags == 1, "Should have exactly 1 diagnostic for our single cron line")

            -- Verify the diagnostic is on the correct line and has expected content
            assert.are.equal(0, diags[1].lnum, "Diagnostic should be on the first line")
            assert.truthy(
                string.match(diags[1].message, "test%-explanation"),
                "Diagnostic message should contain explainer output"
            )

            -- Verify cleanup works
            vim.cmd("CronExplainedDisable")
            local after_diags = vim.diagnostic.get(buf, { namespace = ns })
            assert.are.same({}, after_diags, "Diagnostics should be cleared after disabling")
        end)

        it("Manually enables for .crontab file", function()
            -- Setup plugin without .crontab in patterns
            cronex.setup({
                file_patterns = { "*.yml" }, -- Deliberately exclude crontab
                explainer = {
                    cmd = { "echo", "test-explanation" },
                },
            })

            -- Set buffer and check no diagnostics yet
            vim.api.nvim_set_current_buf(buf)

            -- Get plugin namespace
            local ns = vim.api.nvim_get_namespaces()["plugin-cronex.nvim"]
            assert.is_not_nil(ns, "Plugin namespace should exist")

            local before_diags = vim.diagnostic.get(buf, { namespace = ns })
            assert.are.same({}, before_diags, "Should have no diagnostics before enabling")

            -- Manually enable
            vim.cmd("CronExplainedEnable")
            wait()

            -- Check diagnostics after manual enable
            local after_diags = vim.diagnostic.get(buf, { namespace = ns })
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
                "@daily /another/command",
                "0 */4 * * * run-parts /etc/cron.4hourly",
                "* * * * * 1 2 3 should-only-match-first-5-parts",
                "0 0 * * * 6 should-handle-6-as-cmd",
                "0 1 2 3 4 5 cronwith6parts",
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
                    extract = require("cronex.extract").extract,
                },
                explainer = {
                    cmd = { "echo", "test-explanation" },
                },
            })

            -- Set current buffer and enable plugin
            vim.api.nvim_set_current_buf(unquoted_buf)
            vim.cmd("CronExplainedEnable")

            -- Wait for async operations to complete
            wait()

            -- Get plugin namespace
            local ns = vim.api.nvim_get_namespaces()["plugin-cronex.nvim"]
            assert.is_not_nil(ns, "Plugin namespace should exist")

            -- Get diagnostics for the plugin namespace
            local diags = vim.diagnostic.get(unquoted_buf, { namespace = ns })
            assert.is_not_nil(diags, "Diagnostics should exist")
            assert.is_true(#diags > 0, "Should have diagnostics for cron lines")

            -- Should have diagnostics for all cron lines (not comments)
            assert.are.equal(7, #diags, "Should have 7 diagnostics for all cron lines")

            -- Verify all lines have explanations
            local line_has_diag = {}
            for i = 0, 7 do
                line_has_diag[i] = false
            end

            for _, diag in ipairs(diags) do
                line_has_diag[diag.lnum] = true
            end

            -- Standard 5-part cron expressions
            assert.is_true(line_has_diag[0], "Should recognize '* * * * *' pattern")
            assert.is_true(line_has_diag[1], "Should recognize '30 5 * * 1-5' pattern")
            assert.is_false(line_has_diag[2], "Should ignore comment lines")
            assert.is_true(line_has_diag[3], "Should recognize '@daily' special syntax")
            assert.is_true(line_has_diag[4], "Should recognize '0 */4 * * *' pattern")
            assert.is_true(line_has_diag[5], "Should only match first 5 parts")
            assert.is_true(line_has_diag[7], "Should recognize 6-part cron")

            -- Verify that 6-part cron is recognized correctly
            for _, diag in ipairs(diags) do
                if diag.lnum == 7 then
                    local expected_cron = "1 2 3 4 5" -- 5 parts, ignoring seconds
                    assert.truthy(string.match(diag.message, "test%-explanation"))
                end
            end
        end)

        -- Detailed unit tests for cron_from_line_crontab are in cron_from_line_crontab_spec.lua
    end)
end)
