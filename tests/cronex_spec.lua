describe("api: ", function()
    it("can be required", function()
        require("cronex")
    end)

    it("Commands CronExplainedEnable/Disable are made available on setup", function()
        local cmds = vim.api.nvim_get_commands({})
        assert.are.same(nil, cmds["CronExplainedEnable"])
        assert.are.same(nil, cmds["CronExplainedDisable"])

        require("cronex").setup({})
        cmds = vim.api.nvim_get_commands({})
        assert.are_not.same(nil, cmds["CronExplainedEnable"])
        assert.are_not.same(nil, cmds["CronExplainedDisable"])
    end)

    it("Autocommands are created on enable", function()
        local group = vim.api.nvim_create_augroup("cronex", { clear = true })
        local autocmds = vim.api.nvim_get_autocmds({ group = group })
        assert.are.same({}, autocmds)

        require("cronex").enable()
        autocmds = vim.api.nvim_get_autocmds({ group = group })
        assert.are_not.same({}, autocmds)
    end)

    it("Autocommands react to proper events", function()
        require("cronex").enable()
        local group = vim.api.nvim_create_augroup("cronex", { clear = true })
        local autocmds = vim.api.nvim_get_autocmds({ group = group })
        for _, autocmd in pairs(autocmds) do
            assert.are.same(true,
                vim.tbl_contains({ "InsertEnter", "InsertLeave", "TextChanged" }, autocmd.event))

            if autocmd.event == "InsertEnter" then
                assert.are.same(autocmd.desc, "Hide explanations when entering insert mode")
            elseif autocmd.event == "InsertLeave" then
                assert.are.same(autocmd.desc, "Set explanations when leaving insert mode or changing the text")
            elseif autocmd.event == "TextChanged" then
                assert.are.same(autocmd.desc, "Set explanations when leaving insert mode or changing the text")
            end
        end
    end)
end)
