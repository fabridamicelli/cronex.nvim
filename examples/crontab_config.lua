-- Example configuration for cronex.nvim with support for standard crontab files
-- Place this in your Neovim config

return {
    "fabridamicelli/cronex.nvim",
    config = function()
        require("cronex").setup({
            -- Add *.crontab to supported file patterns
            file_patterns = { "*.yaml", "*.yml", "*.tf", "*.cfg", "*.config", "*.conf", "*.crontab" },

            -- Use custom extractor to support unquoted cron expressions in crontab files
            extractor = {
                -- Use the specialized crontab extractor for all files
                -- This will work on both quoted and unquoted cron expressions
                cron_from_line = require("cronex.cron_from_line").cron_from_line_crontab,

                -- Use the default extract function
                extract = require("cronex.extract").extract,
            },
        })
    end,
}
