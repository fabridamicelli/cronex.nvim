local augroup_name = "plugin-cronex.nvim"

local check_autocmds = function(autocmds)
    -- Make sure the callbacks of the autocmds are correct
    for _, cmd in pairs(autocmds) do
        assert.True(vim.tbl_contains({ "InsertLeave", "TextChanged" }, cmd.event))

        if cmd.event == "InsertLeave" or cmd.event == "TextChanged" then
            assert.are.equal(cmd.desc, "Set explanations when leaving insert mode or changing the text")
        end
    end
end

describe("api - exposed : ", function()
    it("cronex package can be required", function()
        require("cronex")
    end)

    it("Setup makes CronExplainedEnable/Disable available", function()
        local emptycmds = vim.api.nvim_get_commands({})
        assert.equals(nil, emptycmds["CronExplainedEnable"])
        assert.equals(nil, emptycmds["CronExplainedDisable"])

        require("cronex").setup({})
        local cmds = vim.api.nvim_get_commands({})
        assert.are_not.same(nil, cmds["CronExplainedEnable"])
        assert.are_not.same(nil, cmds["CronExplainedDisable"])
    end)

    it("Toggle plugin adds/deletes autocommands", function()
        -- Start clean
        local g = vim.api.nvim_create_augroup(augroup_name, { clear = true })
        assert.are.same({}, vim.api.nvim_get_autocmds({ group = g }))

        -- Activating plugin should make autocmds available
        vim.cmd("CronExplainedEnable")
        local autocmds1 = vim.api.nvim_get_autocmds({ group = g })
        assert.are_not.same({}, autocmds1)
        check_autocmds(autocmds1)

        -- Deactivating plugin should remove autocmds
        vim.cmd("CronExplainedDisable")
        -- Trying to grab a non-existing group (expected behaviour as a result of CronExplainedDisable)
        -- throws an error, so we just catch that one here
        assert.has.errors(
            function()
                local _, err = pcall(function() vim.api.nvim_get_autocmds({ group = g }) end)
                if err ~= nil then
                    local msg = string.match(err, "Invalid 'group':")
                    error(msg)
                end
            end, "Invalid 'group':")

        -- Re-activating plugin should make commands available again
        vim.cmd("CronExplainedEnable")
        local g2 = vim.api.nvim_create_augroup(augroup_name, { clear = false })
        local autocmds2 = vim.api.nvim_get_autocmds({ group = g2 })
        check_autocmds(autocmds2)
    end)

    it("Calling CronExplainedDisable when already disabled throws no error", function()
        assert.has_no.errors(
            function()
                vim.cmd("CronExplainedDisable")
                vim.cmd("CronExplainedDisable")
                vim.cmd("CronExplainedDisable")
            end)
    end)
end)

describe("api - internals: ", function()
    it("M.enable() call creates autocommands", function()
        local group = vim.api.nvim_create_augroup("cronex", { clear = true })
        local emptyautocmds = vim.api.nvim_get_autocmds({ group = group })
        assert.are.same({}, emptyautocmds)

        require("cronex").enable()
        local autocmds = vim.api.nvim_get_autocmds({ group = group })
        check_autocmds(autocmds)
    end)

    it("M.disable() call deletes autocommands", function()
        local group = vim.api.nvim_create_augroup("cronex", { clear = false }) -- clear=false to start with populated group
        local autocmds = vim.api.nvim_get_autocmds({ group = group })
        check_autocmds(autocmds)

        require("cronex").disable()
        local group2 = vim.api.nvim_create_augroup("cronex", { clear = false }) -- keep it false to actually check the state
        local autocmds2 = vim.api.nvim_get_autocmds({ group = group2 })
        assert.are.same({}, autocmds2)
    end)

    it("Autocommands react to proper events", function()
        require("cronex").enable()
        local group = vim.api.nvim_create_augroup("cronex", { clear = true })
        local autocmds = vim.api.nvim_get_autocmds({ group = group })
        check_autocmds(autocmds)
    end)
end)
