local api = vim.api

local M = {}
local augroup_name = "plugin-cronex.nvim"
local augroup = api.nvim_create_augroup(augroup_name, { clear = true })
local ns = api.nvim_create_namespace(augroup_name)

---@param fn function The function to debounce
---@param ms number Debounce delay in milliseconds
---@return function The debounced function
--- Utility to debounce a function
--- Returns a new function that will only execute after the specified delay
--- and cancels any pending executions when called again
local function debounce(fn, ms)
    local timer = nil
    return function(...)
        local args = {...}
        -- Cancel pending execution if any
        if timer then
            vim.loop.timer_stop(timer)
            timer = nil
        end
        
        -- Schedule new execution
        timer = vim.defer_fn(function()
            timer = nil
            fn(unpack(args))
        end, ms)
    end
end

local make_set_explanations = function(config)
    -- Actual explanation function
    local function explain_buffer()
        local bufnr = api.nvim_get_current_buf()
        vim.diagnostic.reset(ns, bufnr)
        local crons = config.extract()
        local explanations = {}
        for lnum, cron in pairs(crons) do
            config.explain(cron, lnum, bufnr, explanations, ns)
        end
    end
    
    -- Debounce the explain function
    return debounce(explain_buffer, 300)
end

M.enable = function()
    local set_explanations = make_set_explanations(M.config)
    -- Recover augroup here in case of call CronExplainedDisable which deletes the augroup
    augroup = api.nvim_create_augroup(augroup_name, { clear = false })
    api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
        group = augroup,
        buffer = 0,
        callback = set_explanations,
        desc = "Set explanations when leaving insert mode or changing the text",
    })
    set_explanations()
end

M.disable = function()
    vim.diagnostic.reset(ns, 0)
    -- pcall: let error (because group no longer exists) go silent
    -- on successive calls to CronExplainedDisable
    pcall(function()
        api.nvim_del_augroup_by_id(augroup)
    end)
end

M.setup = function(opts)
    M.config = require("cronex.config").parse_opts(opts)

    api.nvim_create_user_command(
        "CronExplainedEnable",
        require("cronex").enable,
        { desc = "Enable explanations of cron expressions" }
    )

    api.nvim_create_user_command(
        "CronExplainedDisable",
        require("cronex").disable,
        { desc = "Disable explanations of cron expressions" }
    )

    augroup = api.nvim_create_augroup(augroup_name, { clear = false })
    api.nvim_create_autocmd({ "BufEnter" }, {
        group = augroup,
        pattern = M.config.file_patterns,
        callback = M.enable,
    })
end

return M
