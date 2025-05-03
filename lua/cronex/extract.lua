-- Make table with all pairs (line-number, cron-expressions) in current buffer.
-- If no cron detected, will return an empty table.

local api = vim.api

M = {}

M.extract = function(cron_from_line)
    local bufnr = 0
    local crons = {}
    for i, line in ipairs(api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local cron = cron_from_line(line)
        if cron then
            local lnum = i - 1 -- ipairs starts at 1, so it's off by 1 with respect to line number (0-indexed)
            crons[lnum] = cron
        end
    end
    return crons
end

return M
