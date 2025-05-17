local M = {}

M._config = {
    max_processes = 50,
}

M._cache = {}
M._queue = {}
M._active_processes = 0

local append_explanation = function(explanations, explanation, bufnr, lnum)
    table.insert(explanations, {
        bufnr = bufnr,
        lnum = lnum,
        col = 0,
        message = explanation,
        severity = vim.diagnostic.severity.HINT,
    })
end

local schedule_explanations = function(explanations, ns, bufnr)
    vim.schedule(function()
        vim.diagnostic.set(ns, bufnr, explanations, {})
    end)
end

---@param item table Process queue item containing all parameters needed for expression explanation
---@field cmd table Command to run for explanation
---@field timeout number Timeout in milliseconds
---@field cron_expression string The cron expression to explain
---@field format function Function to format the explanation
---@field bufnr number Buffer number
---@field lnum number Line number
---@field ns number Namespace ID
---@field explanations table Table of explanations to append to
local function process_item(item)
    local cmd = item.cmd
    local timeout = item.timeout
    local cron_expression = item.cron_expression
    local format = item.format
    local bufnr = item.bufnr
    local lnum = item.lnum
    local ns = item.ns
    local explanations = item.explanations
    
    local on_exit = function(obj)
        M._active_processes = M._active_processes - 1
        vim.schedule(function() M.process_next() end)
        
        if obj.signal == 15 and obj.code == 124 then
            vim.schedule(function()
                vim.notify(
                    string.format(
                        "CronExplained Timeout with cmd %s and args %s",
                        vim.inspect(cmd),
                        cron_expression
                    )
                )
            end)
        end

        local data = obj.stdout
        if data ~= "" then
            M._cache[cron_expression] = data
            append_explanation(explanations, format(data), bufnr, lnum)
            schedule_explanations(explanations, ns, bufnr)
        end
    end

    vim.system(vim.iter({ cmd, cron_expression }):flatten():totable(), {
        timeout = timeout,
        text = true,
        stderr = function(_, data)
            if data then
                vim.schedule(function()
                    vim.notify(
                        string.format(
                            "Error calling cmd %s with args %s.\nStderr: \n %s",
                            vim.inspect(cmd),
                            cron_expression,
                            data
                        )
                    )
                end)
            end
        end,
    }, on_exit)
end

M.process_next = function()
    if #M._queue > 0 and M._active_processes < M._config.max_processes then
        M._active_processes = M._active_processes + 1
        local next_item = table.remove(M._queue, 1)
        process_item(next_item)
    end
end

---@param config table Configuration options for the explainer
---@field max_processes number|nil Maximum number of concurrent processes (default: 50)
---@return nil
--- Initialize the explainer module with configuration options
M.setup = function(config)
    config = config or {}
    M._config.max_processes = config.max_processes or M._config.max_processes
end

---@param cmd table Command to run for explanation
---@param timeout number Timeout in milliseconds
---@param cron_expression string The cron expression to explain
---@param format function Function to format the explanation
---@param bufnr number Buffer number
---@param lnum number Line number
---@param ns number Namespace ID
---@param explanations table Table to store explanations
--- Explain a cron expression using an external command
--- Results are cached to avoid duplicate processing
M.explain = function(cmd, timeout, cron_expression, format, bufnr, lnum, ns, explanations)
    local cached = M._cache[cron_expression]
    if cached then
        append_explanation(explanations, format(cached), bufnr, lnum)
        schedule_explanations(explanations, ns, bufnr)
        return
    end
    
    table.insert(M._queue, {
        cmd = cmd,
        timeout = timeout,
        cron_expression = cron_expression,
        format = format,
        bufnr = bufnr,
        lnum = lnum,
        ns = ns,
        explanations = explanations
    })
    
    vim.schedule(function() M.process_next() end)
end

---@return nil
--- Clear the expression explanation cache
--- Call this when explanation behavior or formatting has changed
M.clear_cache = function()
    M._cache = {}
end

return M