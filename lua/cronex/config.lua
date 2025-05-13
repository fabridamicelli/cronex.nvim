local M = {}

-- Default configuration
local defaults = {
    -- File patterns to activate the plugin on
    file_patterns = { "*.yaml", "*.yml", "*.tf", "*.cfg", "*.config", "*.conf" },
    
    -- Functions for extracting cron expressions from code
    extractor = {
        cron_from_line = require("cronex.cron_from_line").cron_from_line,
        extract = require("cronex.extract").extract,
    },
    
    -- Explanation engine settings
    explainer = {
        -- Command to generate human-readable explanations
        cmd = "cronstrue",
        -- Additional arguments for the command
        args = {},
        -- Timeout for explanation commands in milliseconds
        timeout = 10000,
        -- Maximum number of concurrent processes to run
        -- Lower this value if you encounter "too many open files" errors
        max_concurrent = 50,
    },
    
    -- Format output explanations
    format = function(s)
        return s
    end,
}

M.parse_opts = function(opts)
    opts = vim.tbl_deep_extend("force", defaults, opts)

    local extract = function()
        return opts.extractor.extract(opts.extractor.cron_from_line)
    end

    local explain = function(cron, lnum, bufnr, explanations, ns)
        local cmd = vim.iter({ opts.explainer.cmd, opts.explainer.args }):flatten():totable()
        local explain_module = require("cronex.explain")
        
        -- Set up the explainer module with configuration
        explain_module.setup({
            max_processes = opts.explainer.max_concurrent
        })
        
        explain_module.explain(cmd, opts.explainer.timeout, cron, opts.format, bufnr, lnum, ns, explanations)
    end

    return {
        file_patterns = opts.file_patterns,
        extract = extract,
        explain = explain,
    }
end

return M
