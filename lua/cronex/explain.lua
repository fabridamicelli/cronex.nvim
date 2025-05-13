local M = {}

-- Private state
M._cache = {}

-- Process queue to limit concurrent processes
M._queue = {}
M._active_processes = 0
M._max_processes = 50 -- Default, will be overridden by config

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

-- Process an item from the queue
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
        -- Decrease active process count and process next item
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
            -- Update cache
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

-- Process next item in the queue
M.process_next = function()
    if #M._queue > 0 and M._active_processes < M._max_processes then
        M._active_processes = M._active_processes + 1
        local next_item = table.remove(M._queue, 1)
        process_item(next_item)
    end
end

-- Set the maximum number of concurrent processes
M.set_max_processes = function(max_processes)
    M._max_processes = max_processes or 50
end

-- Explain a cron expression
M.explain = function(cmd, timeout, cron_expression, format, bufnr, lnum, ns, explanations)
    -- Use cached result if available
    local cached = M._cache[cron_expression]
    if cached then
        append_explanation(explanations, format(cached), bufnr, lnum)
        schedule_explanations(explanations, ns, bufnr)
        return
    end
    
    -- Add to queue
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
    
    -- Try to process next item
    vim.schedule(function() M.process_next() end)
end

-- Clear the cache
M.clear_cache = function()
    M._cache = {}
end

return M
