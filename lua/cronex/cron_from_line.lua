--[[
NOTE:
Here's the logic extract cron expression from each line using regex + simple parsing.
]]

local M = {}

--Define s to match cronexp in a line. One of three possible lengths (7,6,5)
local first = "['\"]%s?[%d%-%/%*,]+%s" -- Should we allow letters here too?
local part = "[%a%d%-%/%*,%?#]+%s"
local last = "[%a%d%-%/%*,%?#]+%s?['\"]"
local nparts2pat = {
    [7] = first .. part .. part .. part .. part .. part .. last,
    [6] = first .. part .. part .. part .. part .. last,
    [5] = first .. part .. part .. part .. last,
}

local get_cron_for_pat = function(line, pat)
    -- Only allow 1 expression per line
    local n_quotes = 0
    for _ in string.gmatch(line, "['\"]") do
        n_quotes = n_quotes + 1
    end
    if n_quotes > 2 then
        return nil
    end

    -- Build match and count as we go
    local match = ""
    local n_matches = 0
    for m in string.gmatch(line, pat) do
        n_matches = n_matches + 1
        match = match .. m
    end
    if match == "" or n_matches > 1 then
        return nil
    end

    -- Remove " and '
    local clean = ""
    for i = 1, #match do
        local c = string.sub(match, i, i)
        if c ~= "'" and c ~= '"' then
            clean = clean .. c
        end
    end

    -- Strip white space at beginning and end
    if string.sub(clean, 1, 1) == " " then
        clean = string.sub(clean, 2)
    end
    if string.sub(clean, -1, -1) == " " then
        clean = string.sub(clean, 0, -2)
    end

    return clean
end

M.cron_from_line = function(line)
    for n = 7, 5, -1 do
        local pat = nparts2pat[n]
        local match = get_cron_for_pat(line, pat)
        if match then
            return match
        end
    end
    return nil
end

return M
